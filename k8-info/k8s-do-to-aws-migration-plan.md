# DigitalOcean → AWS EKS Full Cluster Migration Plan

**Prepared:** 2026-03-16
**Source:** DigitalOcean Kubernetes (DOKS) — 79 nodes, 183 namespaces, 1,141 pods
**Target:** Amazon Elastic Kubernetes Service (EKS)
**Application:** EMR-Bear Healthcare EHR Platform (Rails 5.2 + Puma)

---

## Table of Contents

1. [Dependency Graph & Migration Order](#1-dependency-graph--migration-order)
2. [Phase 0: Pre-Migration Preparation](#2-phase-0-pre-migration-preparation)
3. [Phase 1: AWS Foundation](#3-phase-1-aws-foundation)
4. [Phase 2: Data Layer Migration](#4-phase-2-data-layer-migration)
5. [Phase 3: Shared Infrastructure Services](#5-phase-3-shared-infrastructure-services)
6. [Phase 4: Platform Services Migration](#6-phase-4-platform-services-migration)
7. [Phase 5: Prex Healthcare Integrations](#7-phase-5-prex-healthcare-integrations)
8. [Phase 6: Tenant Application Migration](#8-phase-6-tenant-application-migration)
9. [Phase 7: DNS Cutover & Decommission](#9-phase-7-dns-cutover--decommission)
10. [Hardcoded References Requiring Code Changes](#10-hardcoded-references-requiring-code-changes)
11. [Risk Register](#11-risk-register)
12. [Rollback Plan](#12-rollback-plan)

---

## 1. Dependency Graph & Migration Order

### Service Dependency Tree (migrate bottom-up)

```
LAYER 0 — External (no migration needed, but config changes required)
├── AWS S3 (us-west-1, bucket: emrbear) ← already on AWS
├── AWS IoT Core (us-west-2) ← already on AWS
├── AWS DynamoDB (us-west-2) ← already on AWS
├── AWS Bedrock (us-west-2) ← already on AWS
├── Stripe API
├── Twilio API
├── Documo API
├── Change Healthcare API
├── Surescripts Network
├── Xero API
├── IDology API
├── Phaxio API
└── RXNT/NCPDP Gateway

LAYER 1 — Data Stores (migrate FIRST)
├── MySQL/MariaDB cluster (3 nodes: 10.138.255.216, 10.138.196.102, 10.138.76.186)
│   └── Per-tenant databases (~167 databases)
│   └── DelayedJob queue tables
│   └── CHC Lab Configuration
│   └── Reminder/Documo Configuration
├── MongoDB (mongodb.default.svc.cluster.local:27017)
│   └── bear3 database (forms, surveys, page content, configs)
├── Memcached (fallacious-bronco-memcached-{0,1})
│   └── Session cache, query cache (ephemeral — rebuild, don't migrate)
└── Redis 4.0.14 (bear-deployer namespace)
    └── Sidekiq queue for bear-deployer (rebuild, don't migrate)

LAYER 2 — Container Registry (migrate SECOND)
└── registry.emrbear.com (in-cluster Docker registry)
    └── Images: bear5:*, bear-deployer:*, bear-services:*, bear_x12:*, bear-xero:*
    └── Storage: DigitalOcean Spaces (sfo3)
    └── TARGET: AWS ECR

LAYER 3 — Shared Platform Services (migrate THIRD)
├── bear-services (services.emrbear.com)
│   ├── bear-services-nginx (reverse proxy)
│   ├── bear-services + bear-services-hds (API + HDS sidecar)
│   └── Depends on: MongoDB, MySQL
├── bear-x12 (parser.emrbear.com)
│   └── X12 EDI parser, 2 replicas
├── bear-xero (bear-xero.emrbear.com)
│   └── Xero accounting connector
├── trip-form-filler (3 replicas)
│   └── AHCCCS PDF form generation
├── bear-stats + bear-github (dash.emrbear.com)
│   └── Analytics dashboard + GitHub API proxy
├── bear-cron (daily + hourly CronJobs)
│   └── Scheduled maintenance tasks
└── Sentry (self-hosted at sentry.emrbear.com)
    └── NOTE: PVCs orphaned, may already be decommissioned

LAYER 4 — Prex Healthcare Services (migrate FOURTH)
├── cerner-web (2 replicas) → Drug/medication data
│   └── Consumed by: all tenant bear-app pods via PREX_DRUGS_HOST
├── production-surescripts-web (2 replicas) + worker
│   └── E-prescribing, consumed by tenant pods
├── staging-surescripts-web + worker
├── production-idology-web → Identity verification
├── staging-idology-web
├── saaspass-web → SSO/MFA
└── 4 CronJobs (Surescripts directory sync)

LAYER 5 — Tenant Applications (migrate LAST)
├── ~167 namespaces, each with:
│   ├── <tenant>-bear-app (Rails/Puma, 1-2 replicas)
│   └── delayed-<tenant>-bear-app-0 (DelayedJob worker, 1 replica)
├── Depends on: ALL of Layers 1-4
│   ├── MySQL (per-tenant DB via <tenant>-bear-db-secrets)
│   ├── MongoDB (via mongoid.yml in <tenant>-bear-app-secrets)
│   ├── Memcached (MEMCACHE_SERVERS env var)
│   ├── bear-services (BearConf.services_url)
│   ├── cerner-web (PREX_DRUGS_HOST)
│   ├── surescripts (via prex/service_endpoint.rb)
│   ├── idology (via prex/identities_controller.rb)
│   ├── saaspass (PREX_SAASPASS_HOST)
│   ├── trip-form-filler (trip_reporter_service.rb)
│   ├── bear-stats (bear_statistics/data_pusher.rb)
│   ├── bear-x12 (parse277.rb)
│   └── Shared secrets: shared-runtime-secrets, mariadb-certs
└── Special namespaces: gemini, demo5, demo6, demotat, staging
```

---

## 2. Phase 0: Pre-Migration Preparation

### 0.1 Fix Pre-Existing Issues

- [ ] Resolve 3 failed Surescripts CronJobs (oldest: 491 days)
  - `production-surescripts-directory-full-sync-29397600` (Failed, 89d)
  - `production-surescripts-directory-nightly-sync-29373120` (Failed, 106d)
  - `staging-surescripts-directory-nightly-sync-28818900` (Failed, 491d)
- [ ] Investigate orphaned resources:
  - `latex-service` ClusterIP in `services` (no backing deployment)
  - `surescripts-web` ClusterIP in `prex` (no backing deployment)
  - Sentry PVCs (24Gi total, 0 running pods)
- [ ] Decommission legacy nginx-ingress v1 controller (`nginx-ingress-controller-manual`)
- [ ] Confirm `bear-deployer` (scaled to 0) and `production-gemini-web` (scaled to 0) disposition — migrate or drop?

### 0.2 Add Missing Resource Requests/Limits

- [ ] All `prex` namespace workloads have **zero** CPU/memory requests — profile with `kubectl top pods -n prex` and VPA recommendation mode
- [ ] All `services` namespace workloads are missing CPU **limits**
- [ ] Apply resource specs before migration so EKS node sizing is accurate

### 0.3 Audit External Partner IP Allowlists

Contact these partners about upcoming public IP change (DO → AWS):
- [ ] Surescripts (e-prescribing network) — TLS client cert may also be IP-bound
- [ ] Xero (accounting API)
- [ ] IDology (identity verification)
- [ ] Cerner (EHR)
- [ ] Change Healthcare (lab ordering)
- [ ] Phaxio (faxing)
- [ ] Documo (faxing)
- [ ] Mailgun (email — `system.emrbear.com` domain)

### 0.4 Inventory All Secrets

Export secret **names and keys** (not values) for all namespaces:
- [ ] 713 Opaque secrets
- [ ] 177 dockerconfigjson secrets (registry pull creds)
- [ ] Per-tenant: `<tenant>-bear-app-secrets` + `<tenant>-bear-db-secrets`
- [ ] Cluster-wide: `shared-runtime-secrets`, `mariadb-certs` (replicated ~167 times)
- [ ] Infrastructure: `bear-deployer-secrets`, `services-db-secrets`, `bear-xero-secrets`, `registry-secret`
- [ ] Prex: `cerner-secrets`, `idology-secrets`, `surescripts-secrets`, `surescripts-connection-cert`, `saaspass-secrets`, `prex-aws-secrets`, `prex-postgres-secrets`

### 0.5 Code Changes Required Before Migration

See [Section 10](#10-hardcoded-references-requiring-code-changes) for the full list. Critical items:

- [ ] **SECURITY FIX**: Remove hardcoded X12 credentials from `app/lib/modules/parsers/x12/parse277.rb` (lines 61, 63) — move to environment variable or secret
- [ ] Extract all `*.svc.cluster.local` references to environment variables (they'll change if service names/namespaces change)
- [ ] Update HAProxy configs (`k8s/haproxy-config.yaml`, `k8s/haproxy-lb.yaml`, `k8s/haproxy.cfg`) with new database IPs
- [ ] Update CI/CD pipelines (`.drone.yml`, `.github/workflows/`, `Jenkinsfile`) to reference ECR instead of `registry.emrbear.com`

---

## 3. Phase 1: AWS Foundation

### 1.1 EKS Cluster Provisioning

```
Kubernetes version: v1.32 (match current DOKS version)
Region: us-west-2 (co-locate with existing AWS services: IoT, DynamoDB, Bedrock, S3)
```

### 1.2 Node Groups

| Node Group | Instance Type | Count | Purpose | Taints/Labels |
|---|---|---|---|---|
| `standard-pool` | `m6i.2xlarge` (8 vCPU / 32 GB) | 40 | Tenant bear-app pods | `pool=standard` |
| `delayed-job` | `m6i.xlarge` (4 vCPU / 16 GB) | 38 | DelayedJob workers | `pool=delayed-job` |
| `monitoring` | `t3.medium` (2 vCPU / 4 GB) | 1 | Prometheus, Grafana | `pool=monitoring` |

- [ ] Reproduce node labels and taints from DO pools
- [ ] Enable cluster autoscaler or Karpenter

### 1.3 Networking

- [ ] VPC with private subnets (pods) + public subnets (load balancers)
- [ ] VPC peering or Transit Gateway to RDS/DocumentDB VPC if separate
- [ ] Security groups mirroring current NetworkPolicy rules:
  - Tenant pods: inbound 8080/80 only from ingress, bear-stats, bear-cron namespaces
  - No cross-tenant traffic

### 1.4 Storage Classes

| DO Class | EKS Replacement | Provisioner |
|---|---|---|
| `do-block-storage` | `gp3` (default) | `ebs.csi.aws.com` |
| `do-block-storage-retain` | `gp3-retain` | `ebs.csi.aws.com`, reclaimPolicy: Retain |
| `do-block-storage-xfs` | `gp3-xfs` | `ebs.csi.aws.com`, fsType: xfs |
| `do-block-storage-xfs-retain` | `gp3-xfs-retain` | `ebs.csi.aws.com`, fsType: xfs, Retain |

- [ ] Install AWS EBS CSI driver
- [ ] Create StorageClasses

### 1.5 Ingress Controller

- [ ] Install ingress-nginx v2 with AWS NLB (LoadBalancer service type)
- [ ] Configure TLS termination via ACM + cert-manager (currently TLS is terminated upstream)
- [ ] Single ingress class: `nginx`

### 1.6 Secrets Management

- [ ] Deploy AWS Secrets Manager CSI driver OR External Secrets Operator
- [ ] Create IAM roles for service accounts (IRSA) — replace all static AWS credentials:
  - `prex-aws-secrets` → IRSA
  - `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` in `shared-runtime-secrets` → IRSA
  - Velero cloud credentials → IRSA
- [ ] Provision all Opaque secrets into AWS Secrets Manager, organized by namespace

### 1.7 Container Registry (ECR)

- [ ] Create ECR repositories:
  - `bear5` (main app — production + develop tracks)
  - `bear-deployer`
  - `bear-services`
  - `bear-services-hds`
  - `bear_x12`
  - `bear-xero`
  - `bear-cron`
  - `bear-stats`
  - `bear-github`
  - `bear-gemini`
  - `curl` (used by CI)
- [ ] Mirror all images from `registry.emrbear.com` to ECR
- [ ] Verify `ghcr.io/emrbear/*` images (prex services, trip-reporter) pull correctly from EKS
- [ ] Create ECR pull secrets for each namespace (or use IRSA for ECR authentication)

### 1.8 Monitoring Stack

- [ ] Deploy kube-prometheus-stack (Grafana 9.x, Prometheus v2.39+, Alertmanager)
- [ ] Create 50Gi gp3 PVC for Prometheus TSDB
- [ ] Deploy `mysql-exporter` pointing to new RDS endpoint
- [ ] Migrate Grafana dashboards (export JSON from DO cluster)
- [ ] Configure Alertmanager rules

---

## 4. Phase 2: Data Layer Migration

### 2.1 MySQL/MariaDB → AWS RDS

**Current state:** 3-node MariaDB cluster on DO droplets:
- Primary: `10.138.255.216:3306`
- Replica 1: `10.138.196.102:3306` (backup)
- Replica 2: `10.138.76.186:3306` (backup)
- Load balanced via HAProxy (in-cluster)
- ~167 tenant databases + infrastructure databases

**Target:** Amazon RDS for MariaDB (Multi-AZ)

| Property | Value |
|---|---|
| Engine | MariaDB 10.6+ (compatible with current 10.2.29, test upgrade) |
| Instance class | `db.r6g.2xlarge` or larger (profile first) |
| Multi-AZ | Yes |
| Storage | gp3, sized to current data + 50% headroom |
| Encryption | At rest (KMS) + in transit (TLS) |
| Parameter group | Match current MariaDB tuning |

**Migration steps:**
- [ ] Create RDS instance in same VPC as EKS
- [ ] Set up DMS (Database Migration Service) replication from DO MariaDB → RDS
- [ ] Validate all ~167 tenant databases replicate correctly
- [ ] Test application connectivity from EKS pods to RDS
- [ ] Update `<tenant>-bear-db-secrets` (`database.yml`, `.my.cnf`) to point to RDS endpoint
- [ ] Update HAProxy config or remove HAProxy entirely (RDS has built-in failover)
- [ ] Update `mariadb-certs` secret with new RDS TLS certificates (use Amazon RDS CA bundle)
- [ ] **CI/CD:** Update `BEAR_DATABASE_HOST` in `.drone.yml` (currently hardcoded to `10.138.56.0`)

### 2.2 MongoDB → Amazon DocumentDB (or self-hosted on EKS)

**Current state:** External droplet accessed via `mongodb.default.svc.cluster.local:27017`
**Database:** `bear3` (forms, surveys, page content, configs)

**Option A — Amazon DocumentDB (recommended):**
- [ ] Create DocumentDB cluster (MongoDB 4.0 compatible)
- [ ] Use `mongodump`/`mongorestore` for migration
- [ ] Update `services-db-secrets` (`mongo-password`)
- [ ] Update `mongoid.yml` in `<tenant>-bear-app-secrets` to point to DocumentDB endpoint
- [ ] Update `BEAR_MONGO_HOST` environment variable

**Option B — Self-hosted MongoDB on EKS:**
- [ ] Deploy MongoDB StatefulSet with persistent volumes
- [ ] Not recommended — operational overhead

### 2.3 Prex PostgreSQL → Amazon RDS PostgreSQL

**Current state:** Referenced by `prex-postgres-secrets` and `prex-postgres-staging-secrets`
**Used by:** cerner-web, surescripts, saaspass, idology

- [ ] Identify current PostgreSQL host (inspect secret values)
- [ ] Create RDS PostgreSQL instance
- [ ] Migrate data via `pg_dump`/`pg_restore` or DMS
- [ ] Update `prex-postgres-secrets` and `prex-postgres-staging-secrets`

### 2.4 Elasticsearch (Prex)

**Current state:** Referenced by `prex-elasticsearch-config` ConfigMap
- [ ] Identify current Elasticsearch host
- [ ] Migrate to Amazon OpenSearch Service or self-hosted on EKS
- [ ] Update `prex-elasticsearch-config`

### 2.5 Memcached (Ephemeral — Rebuild)

**Current state:** StatefulSet `fallacious-bronco-memcached-{0,1}` in `default` namespace

- [ ] Deploy Amazon ElastiCache for Memcached (2 nodes, matching current topology)
- [ ] OR deploy Memcached StatefulSet on EKS
- [ ] Update `MEMCACHE_SERVERS` env var in all tenant deployments
  - Current: `fallacious-bronco-memcached-0.fallacious-bronco-memcached.default.svc.cluster.local:11211:1,...`
  - New: ElastiCache endpoint or new StatefulSet DNS

### 2.6 Redis (Rebuild)

**Current state:** `redis-bear-deployer-master` StatefulSet in `bear-deployer` namespace (Bitnami Redis 4.0.14)
**Also:** ActionCable requires Redis in production (`config/cable.yml` → `REDIS_URL`)

- [ ] Deploy Amazon ElastiCache for Redis or Redis StatefulSet on EKS
- [ ] Update `bear-deployer-secrets` (`REDIS_URL`)
- [ ] Update `REDIS_URL` for ActionCable in tenant pods (if not already in `shared-runtime-secrets`)

---

## 5. Phase 3: Shared Infrastructure Services

### 3.1 `services` Namespace

Deploy in order:

1. **bear-services-nginx** + **bear-services** (+ bear-services-hds sidecar)
   - Update image refs to ECR
   - Update `services-db-secrets` with DocumentDB/MongoDB credentials
   - Verify `services.emrbear.com` ingress
   - Test: `curl https://services.emrbear.com/static/icd10cm_order_latest.txt` (static file serving)

2. **bear-x12** (2 replicas)
   - Update image ref to ECR
   - Update `bear-x12-secrets`
   - Verify `parser.emrbear.com` ingress

3. **bear-xero**
   - Update image ref to ECR
   - Update `bear-xero-secrets`, `xero-config`
   - Verify `bear-xero.emrbear.com` ingress

4. **trip-form-filler** (3 replicas)
   - Image from `ghcr.io/emrbear` — no registry change needed
   - Verify internal service at `trip-form-filler.services.svc.cluster.local:4567`

5. **docker-registry** — Decision point:
   - **Option A:** Migrate to ECR fully, decommission in-cluster registry
   - **Option B:** Redeploy on EKS pointing to S3 (instead of DO Spaces)
   - Recommendation: **Option A** — use ECR, update all CI/CD pipelines

### 3.2 `bear-stats` Namespace

- [ ] Deploy `bear-stats` + `bear-github`
- [ ] Update image refs to ECR
- [ ] Update `bear-github-secrets`
- [ ] Verify `dash.emrbear.com` ingress

### 3.3 `bear-cron` Namespace

- [ ] Deploy `bear-daily-job` CronJob (07:00 UTC)
- [ ] Deploy `bear-hourly-job` CronJob
- [ ] Update image refs to ECR

### 3.4 `bear-deployer` Namespace (if keeping)

- [ ] Deploy `redis-bear-deployer-master` StatefulSet
- [ ] Deploy `bear-deployer` + `bear-deployer-sidekiq`
- [ ] Update secrets, scale to desired replicas
- [ ] Verify `bear-deployer.emrbear.com` ingress

### 3.5 `monitoring` Namespace

- [ ] Deploy kube-prometheus-stack (see Phase 1.8)
- [ ] Deploy `mysql-exporter-m3` pointing to RDS

### 3.6 `velero` Namespace

- [ ] Deploy Velero v1.10+ with AWS plugin
- [ ] Configure S3 backup bucket
- [ ] Use IRSA instead of static cloud credentials

### 3.7 Sentry

- [ ] Decision: keep self-hosted `sentry.emrbear.com` or migrate to Sentry SaaS?
- [ ] If keeping: deploy Sentry Helm chart on EKS with Redis + Postgres
- [ ] If not: update all `SENTRY_DSN` values in `shared-runtime-secrets`

---

## 6. Phase 4: Platform Services Migration

**Validate all Layer 3 services are healthy before proceeding.**

### 4.1 `gemini` Namespace

- [ ] Deploy `staging-gemini-web` + `staging-gemini-worker`
- [ ] Update `gemini-staging-secrets`
- [ ] Decide on `production-gemini-web` (currently scaled to 0)
- [ ] Verify `gemini-staging.emrbear.com` ingress

---

## 7. Phase 5: Prex Healthcare Integrations

### 5.1 Prerequisites

- [ ] Prex PostgreSQL available on RDS (Phase 2.3)
- [ ] Prex Elasticsearch available on OpenSearch (Phase 2.4)
- [ ] Surescripts IP allowlist updated with AWS NAT Gateway IPs
- [ ] `surescripts-connection-cert` TLS client certificate verified/re-issued for new IPs

### 5.2 Deployment Order

1. **cerner-web** (2 replicas) — Drug data, consumed by all tenant pods
   - Secrets: `cerner-secrets`, `prex-aws-secrets` (→ IRSA), `prex-postgres-secrets`
   - Config: `cerner-config`
   - Test: `curl http://cerner-web.prex.svc.cluster.local/drugs/search_monographs?filename=d00148a1.htm`

2. **saaspass-web** — SSO/MFA
   - Secrets: `saaspass-secrets`, `prex-postgres-secrets`
   - Config: `saaspass-config`

3. **production-idology-web** + **staging-idology-web** — Identity verification
   - Secrets: `idology-secrets`
   - Config: `idology-config`

4. **production-surescripts-web** (2 replicas) + **production-surescripts-worker**
   - Secrets: `surescripts-secrets`, `surescripts-connection-cert`, `prex-aws-secrets`, `prex-postgres-secrets`
   - Config: `surescripts-config`
   - Ingress: `surescripts-production.emrbear.com`

5. **staging-surescripts-web** + **staging-surescripts-worker**
   - Secrets: `surescripts-staging-secrets`, `surescripts-connection-cert`
   - Config: `surescripts-config-staging`
   - Ingress: `surescripts-staging.emrbear.com`

6. **CronJobs:**
   - `production-surescripts-directory-full-sync` (Sundays)
   - `production-surescripts-directory-nightly-sync` (Mon-Fri)
   - `staging-surescripts-directory-full-sync` (Saturdays)
   - `staging-surescripts-directory-nightly-sync` (Mon-Fri)

### 5.3 Validation

- [ ] Prescription creation end-to-end test
- [ ] Drug search via Cerner
- [ ] Identity verification via IDology
- [ ] SaaSPass authentication flow
- [ ] Surescripts directory sync runs successfully

---

## 8. Phase 6: Tenant Application Migration

### 6.1 Per-Tenant Migration Checklist

For each of the ~167 tenant namespaces:

- [ ] Create namespace on EKS
- [ ] Deploy secrets:
  - `<tenant>-bear-app-secrets` (SECRET_KEY_BASE, master.key, aws.yml, mongoid.yml, symmetric-encryption keys)
  - `<tenant>-bear-db-secrets` (database.yml → RDS endpoint, .my.cnf → RDS endpoint)
  - `shared-runtime-secrets` (AWS_IOT_ENDPOINT, BEAR_GEMINI_URL, SENTRY_DSN)
  - `mariadb-certs` (RDS CA certificates)
  - `emrbear-registry-secret` (ECR pull secret or IRSA)
- [ ] Deploy ConfigMap: `<tenant>-bear-app-config` (custom_hosts)
- [ ] Deploy NetworkPolicy: `ingress-network-policy` (allow ingress from nginx-ingress, bear-stats, bear-cron)
- [ ] Deploy `<tenant>-bear-app` Deployment (1-2 replicas)
  - Image: ECR `bear5:<branch>-<sha>`
  - Env: `MEMCACHE_SERVERS` → new ElastiCache/Memcached endpoint
  - Verify: pods healthy, Rails boots, DB connection works
- [ ] Deploy `delayed-<tenant>-bear-app-0` Deployment (1 replica)
- [ ] Deploy Services: `<tenant>-bear-app` (ClusterIP:8080), `maintenance-page` (ClusterIP:80)
- [ ] Deploy Ingress: `<tenant>.emrbear.com` → `<tenant>-bear-app:8080`

### 6.2 Recommended Batch Strategy

| Batch | Tenants | Purpose |
|---|---|---|
| Batch 0 | `staging`, `demotat`, `demo5`, `demo6` | Test environments — validate full flow |
| Batch 1 | 5 low-traffic tenants on `develop` track | Canary production validation |
| Batch 2 | 20 tenants (smallest by user count) | Expand confidence |
| Batch 3 | 50 tenants | Bulk migration |
| Batch 4 | Remaining ~90 tenants | Complete migration |
| Batch 5 | `gemini`, `prex` staging/prod stragglers | Final cleanup |

### 6.3 Per-Batch Validation

- [ ] Tenant app loads at `https://<tenant>.emrbear.com`
- [ ] User login works (session via Memcached)
- [ ] Patient record CRUD (MySQL)
- [ ] Document upload (S3)
- [ ] Prescription workflow (Surescripts → Prex)
- [ ] Fax send/receive (Twilio/Documo)
- [ ] DelayedJob background processing
- [ ] ActionCable WebSocket connectivity (Redis)

---

## 9. Phase 7: DNS Cutover & Decommission

### 7.1 DNS Records to Update

| Domain | Current Target | New Target |
|---|---|---|
| `*.emrbear.com` (wildcard) | DO LB `10.245.201.84` | AWS NLB/ALB IP or CNAME |
| `services.emrbear.com` | DO cluster | EKS ingress |
| `parser.emrbear.com` | DO cluster | EKS ingress |
| `bear-xero.emrbear.com` | DO cluster | EKS ingress |
| `dash.emrbear.com` | DO cluster | EKS ingress |
| `bear-deployer.emrbear.com` | DO cluster | EKS ingress |
| `registry.emrbear.com` | DO cluster | ECR (or decommission) |
| `sentry.emrbear.com` | DO cluster | EKS or Sentry SaaS |
| `surescripts-production.emrbear.com` | DO cluster | EKS ingress |
| `surescripts-staging.emrbear.com` | DO cluster | EKS ingress |
| `gemini-staging.emrbear.com` | DO cluster | EKS ingress |
| `assets.emrbear.com` | ? | AWS CloudFront + S3 |
| `help.emrbear.com` | ? | Verify — may be external |
| `tainted.emrbear.com` | ? | Verify — outside referral system |
| `system.emrbear.com` | Mailgun | Update SPF/DKIM if IP changes |

### 7.2 Strategy

- **Option A (recommended):** Use weighted DNS (Route 53) to gradually shift traffic from DO → AWS
- **Option B:** Hard cutover with short TTL (riskier)

### 7.3 Decommission DO Cluster

- [ ] Verify zero traffic hitting DO cluster (monitor nginx-ingress access logs)
- [ ] Take final backups via Velero
- [ ] Delete DO Kubernetes cluster
- [ ] Delete DO Droplets (MariaDB nodes, MongoDB) after RDS validation period
- [ ] Delete DO Spaces storage (registry data) after ECR migration confirmed
- [ ] Cancel DO infrastructure billing

---

## 10. Hardcoded References Requiring Code Changes

### CRITICAL — Security

| File | Line | Issue | Fix |
|---|---|---|---|
| `app/lib/modules/parsers/x12/parse277.rb` | 61 | Hardcoded credentials: `emr-bear:88163381e51c2b08fecf1147710c538fc79a36d1` in cluster-local URL | Move to env var or Kubernetes secret |
| `app/lib/modules/parsers/x12/parse277.rb` | 63 | Same credentials in `parser.emrbear.com` URL | Move to env var or Kubernetes secret |

### HIGH — Kubernetes Service DNS (*.svc.cluster.local)

These are defaults that fall back when env vars are not set. If namespaces and service names remain identical on EKS, **no code change is needed**. But they should be externalized to env vars for portability:

| File | Line | Reference | Env Var Override |
|---|---|---|---|
| `app/lib/prex/medication/base.rb` | 28 | `cerner-web.prex.svc.cluster.local` | `PREX_DRUGS_HOST` ✅ exists |
| `app/services/prex/drug/create.rb` | 38 | `cerner-web.prex.svc.cluster.local` | `PREX_DRUGS_HOST` ✅ exists |
| `app/services/prex/supply/create.rb` | 49 | `cerner-web.prex.svc.cluster.local` | `PREX_DRUGS_HOST` ✅ exists |
| `app/services/prex/consents/request_monograph.rb` | 26 | `cerner-web.prex.svc.cluster.local` | `PREX_DRUGS_HOST` ✅ exists |
| `app/controllers/prex/identities_controller.rb` | 152 | `idology-web.prex.svc.cluster.local` | **Needs env var** (`PREX_IDOLOGY_HOST`) |
| `app/lib/prex/saaspass/base.rb` | 47 | `saaspass-web.prex.svc.cluster.local` | `PREX_SAASPASS_HOST` ✅ exists |
| `app/models/fund/invoice/remote_client.rb` | 2 | `bear-xero.services.svc.cluster.local:4567` | **Needs env var** (`BEAR_XERO_ENDPOINT`) |
| `app/lib/modules/parsers/x12/parse277.rb` | 61 | `bear-x12.services.svc.cluster.local:3000` | **Needs env var** |
| `app/services/trip_reporter_service.rb` | 4 | `trip-form-filler.services.svc.cluster.local:4567` | **Needs env var** |
| `app/classes/bear_statistics/data_pusher.rb` | 47-48 | `bear-stats.bear-stats.svc.cluster.local:3000` | `BEAR_STATS_URL` ✅ exists (fallback) |
| `app/controllers/releases_changelog_controller.rb` | 27 | `bear-stats.bear-stats.svc.cluster.local:3000` | **Needs env var** |
| `app/classes/bear_conf.rb` | 23-24 | `bear-services.services.svc.cluster.local` | Fallback, has DNS check + `services.emrbear.com` external fallback ✅ |

### MEDIUM — Hardcoded DigitalOcean IPs

| File | Line | IP | Purpose | Fix |
|---|---|---|---|---|
| `k8s/haproxy-config.yaml` | 34-36 | `10.138.255.216`, `10.138.196.102`, `10.138.76.186` | MariaDB cluster nodes | Replace with RDS endpoint |
| `k8s/haproxy-lb.yaml` | 41-43 | Same 3 IPs | MariaDB load balancer | Replace with RDS or remove HAProxy |
| `k8s/haproxy.cfg` | 25-27 | Same 3 IPs | MariaDB config | Replace with RDS or remove HAProxy |
| `.drone.yml` | 41 | `10.138.56.0` | CI database host | Update to CI database endpoint |
| `.drone.yml` | 86, 102 | `10.138.192.109` | K8s API via HAProxy | Update to EKS API endpoint |
| `app/lib/modules/billing/magellan.rb` | 31-32 | `10.138.108.116:1080` | SOCKS proxy for Magellan billing | Update to new proxy or direct route |

### MEDIUM — CI/CD Pipeline Updates

| File | Lines | Issue | Fix |
|---|---|---|---|
| `.drone.yml` | 16-17, 37, 82, 98 | `registry.emrbear.com` image refs | Update to ECR |
| `.github/workflows/deploy_production.yml` | 48-52, 74 | `registry.emrbear.com/bear5` | Update to ECR |
| `.github/workflows/deploy_staging.yml` | 38, 40, 145 | `registry.emrbear.com` | Update to ECR |
| `Jenkinsfile` | 10, 61, 76, 146-147, 164 | `registry.emrbear.com`, `bear-deployer.emrbear.com` | Update to ECR + new deployer URL |

### LOW — Domain References (functional, don't need code changes)

These use `*.emrbear.com` public domains that will continue to work after DNS cutover:
- `config/environments/production.rb:33` — `assets.emrbear.com` (asset host)
- `config/environments/production.rb:95-96` — `system.emrbear.com` (Mailgun)
- `app/services/prex/service_endpoint.rb:32` — `surescripts-{env}.emrbear.com`
- `app/classes/bear_conf.rb:27` — `services.emrbear.com` (external fallback)
- `app/classes/bear_statistics/data_pusher.rb:51` — `dash.emrbear.com`
- `app/classes/outside_referral.rb:120,128` — `tainted.emrbear.com`
- Fax callback URLs using `BearConf.subdomain` — dynamic, will resolve correctly
- `config/initializers/cors.rb:4` — `emrbear.com` CORS origin ✅
- Static file rake tasks referencing `services.emrbear.com/static/*` ✅

---

## 11. Risk Register

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| 1 | Database migration data loss/corruption | **Critical** | Use DMS with continuous replication; validate row counts + checksums per tenant DB |
| 2 | Surescripts connectivity failure (IP change + TLS cert) | **Critical** | Pre-coordinate with Surescripts; test in staging first; have rollback DNS ready |
| 3 | In-cluster registry unavailable during transition | **High** | Mirror all images to ECR before starting; keep DO registry running until all pods on EKS pull from ECR |
| 4 | Secret values lost/mismatched during re-provisioning | **High** | Script secret export (values) from DO; import to AWS Secrets Manager; automate verification |
| 5 | Cross-service DNS resolution failures | **High** | Keep identical namespace + service names on EKS; test all `*.svc.cluster.local` references |
| 6 | Memcached cache invalidation causing session drops | **Medium** | Coordinate cutover during low-traffic window; warn users of potential re-login |
| 7 | Change Healthcare IP allowlist not updated | **Medium** | Contact CHC before migration; use NAT Gateway with static Elastic IPs |
| 8 | DelayedJob queue backlog during migration | **Medium** | Drain DelayedJob queue before tenant cutover; monitor `delayed_jobs` table |
| 9 | MongoDB/DocumentDB compatibility issues (Mongoid 7.0.2) | **Medium** | Test DocumentDB compatibility mode; Mongoid 7.x supports MongoDB 4.0 API |
| 10 | Magellan billing SOCKS proxy unreachable | **Medium** | Identify proxy location; re-provision on AWS or establish VPN back to DO network |

---

## 12. Rollback Plan

### Per-Phase Rollback

| Phase | Rollback Action | RTO |
|---|---|---|
| Phase 1 (AWS Foundation) | Delete EKS cluster + resources | Clean, no impact |
| Phase 2 (Data Layer) | Stop DMS replication; DO databases remain primary | Minutes |
| Phase 3-5 (Services) | DNS still points to DO; EKS services are secondary | No user impact |
| Phase 6 (Tenants) | Revert DNS to DO LB IP; DO pods still running | Minutes (DNS TTL) |
| Phase 7 (DNS Cutover) | Revert DNS records to DO endpoints | DNS TTL (keep low: 60s during cutover) |

### Key Principle
Run both clusters in parallel until EKS is fully validated. DO cluster remains the primary until DNS cutover. Database replication runs DO → AWS (DMS), so DO always has the latest data until final cutover.

