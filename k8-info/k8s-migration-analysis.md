# Kubernetes Migration Analysis: DigitalOcean → AWS EKS
**Prepared:** 2026-02-20
**Scope:** Namespaces `services` and `prex`
**Source cluster:** DigitalOcean Kubernetes (DOKS)
**Target:** Amazon Elastic Kubernetes Service (EKS)

---

## 1. Cluster Overview

| Property | Value |
|---|---|
| Kubernetes version | v1.32.10 |
| Container runtime | containerd 1.6.33 |
| Node OS | Debian GNU/Linux 12 (Bookworm) |
| Total nodes | 79 |
| Total namespaces | ~170 (many tenant namespaces) |
| Ingress controller | ingress-nginx (two deployed versions: v1 legacy + v2 active) |

### 1.1 Node Pools

| Pool Name | Instance Type | DO Spec | Recommended AWS Equivalent | Node Count |
|---|---|---|---|---|
| `standard-pool` | s-6vcpu-16gb | 6 vCPU / 16 GB RAM | `m6i.xlarge` (4 vCPU / 16 GB) or `m6i.2xlarge` (8 vCPU / 32 GB) | 40 |
| `delayed-job` | s-6vcpu-16gb | 6 vCPU / 16 GB RAM | `m6i.xlarge` or `m6i.2xlarge` | 38 |
| `monitoring` | s-2vcpu-4gb | 2 vCPU / 4 GB RAM | `t3.medium` (2 vCPU / 4 GB) | 1 |

> **Note:** AWS `m6i.xlarge` provides 4 vCPU / 16 GB for general workloads. If current CPU headroom on DO nodes is needed, `m6i.2xlarge` (8 vCPU / 32 GB) is the safe choice. The consulting team should validate against actual `kubectl top nodes` usage data. The `delayed-job` pool name implies workload-specific scheduling — node taints and labels will need to be reproduced on EKS managed node groups.

---

## 2. Namespace: `services`

### 2.1 Deployments

| Name | Replicas | Container(s) | Image Registry | CPU Req | Mem Req | CPU Limit | Mem Limit |
|---|---|---|---|---|---|---|---|
| `bear-services` | 1 | `services`, `services-hds` | `registry.emrbear.com` ⚠️ | 250m + 250m | 1Gi + 1Gi | none | none |
| `bear-services-nginx` | 1 | `nginx` | `nginx:alpine` (Docker Hub) | 250m | 200Mi | none | none |
| `bear-x12` | 2 | `app` | `registry.emrbear.com` ⚠️ | 20m | 200Mi | none | none |
| `bear-xero` | 1 | `bear-xero` | `registry.emrbear.com` ⚠️ | 250m | 250Mi | none | none |
| `docker-registry` | 1 | `registry` | `registry:2.7.1` (Docker Hub) | 400m | 5Gi | none | none |
| `trip-form-filler` | 3 | `app` | `ghcr.io/emrbear` | 50m | 700Mi | none | none |

> **Observation:** No CPU limits are set on any workload in this namespace. This is a best-practice gap that should be addressed in the migration.

### 2.2 StatefulSets / DaemonSets / CronJobs / Jobs

None found in `services` namespace.

### 2.3 Services

| Name | Type | Port(s) | Selector |
|---|---|---|---|
| `bear-services` | ClusterIP | 80 | `bear-services-nginx` |
| `bear-services-backend` | ClusterIP | 8080, 8081 | `bear-services` |
| `bear-x12` | ClusterIP | 3000 | `bear-x12` |
| `bear-xero` | ClusterIP | 4567 | `bear-xero` |
| `docker-registry` | ClusterIP | 5000 | `docker-registry` |
| `latex-service` | ClusterIP | 9000 | `latex-service` (no active deployment found) |
| `nginx-test` | ClusterIP | 80 | `nginx` test pod |
| `trip-form-filler` | ClusterIP | 4567 | `trip-form-filler` |

All services are ClusterIP — external traffic enters via Ingress only.

> **`latex-service`:** Has a ClusterIP service but no corresponding deployment was found. Likely orphaned — confirm before migration.

### 2.4 Ingress Resources

| Name | Host | Backend Service | Ingress Class |
|---|---|---|---|
| `bear-services` | `services.emrbear.com` | `bear-services:80` | `nginx` |
| `bear-x12` | `parser.emrbear.com` | `bear-x12:80` (via nginx) | `nginx` |
| `bear-xero-ingress` | `bear-xero.emrbear.com` | `bear-xero:80` (via nginx) | `nginx` |
| `docker-registry` | `registry.emrbear.com` | `docker-registry:5000` | `nginx` |

> **TLS:** No TLS termination configured at the Ingress level for these hosts. Verify whether TLS is handled upstream (CDN/proxy) or if this needs to be added on EKS.

### 2.5 Persistent Volume Claims

None. No stateful storage in this namespace.

### 2.6 Horizontal Pod Autoscalers

None configured.

### 2.7 ConfigMaps

| Name | Purpose |
|---|---|
| `kube-root-ca.crt` | Auto-injected cluster CA |
| `registry-config` | Docker registry configuration |
| `services-nginx-config` | Nginx configuration for bear-services |
| `xero-config` | Xero API connector configuration |

### 2.8 Secrets ⚠️ Migration Blockers

| Secret Name | Type | Notes |
|---|---|---|
| `bear-x12-secrets` | Opaque | Application credentials for X12 parser |
| `bear-xero-secrets` | Opaque | Xero OAuth credentials |
| `emrbear-registry-secret` | `kubernetes.io/dockerconfigjson` | Pull credentials for `registry.emrbear.com` — **critical: tied to in-cluster registry** |
| `github-registry` | `kubernetes.io/dockerconfigjson` | Pull credentials for `ghcr.io` |
| `registry-secret` | Opaque | Docker registry auth/storage secret |
| `services-db-secrets` | Opaque | Database connection credentials |

> **Action required:** All Opaque secrets must be audited, re-provisioned, and stored in AWS Secrets Manager or SSM Parameter Store. Consider using the AWS Secrets Manager CSI driver or External Secrets Operator to inject them into EKS pods without storing them as plain Kubernetes Secrets.

### 2.9 Service Accounts

Default service account only. No custom RBAC.

---

## 3. Namespace: `prex`

### 3.1 Deployments

| Name | Replicas | Container(s) | Image | CPU Req | Mem Req |
|---|---|---|---|---|---|
| `cerner-web` | 2 | `web` | `ghcr.io/emrbear/prex-cerner` | **none** | **none** |
| `idology-web` | 1 | `web` | `ghcr.io/emrbear/prex-idology` | **none** | **none** |
| `production-idology-web` | 1 | `web` | `ghcr.io/emrbear/prex-idology` | **none** | **none** |
| `production-surescripts-web` | 2 | `production-web` | `ghcr.io/emrbear/prex-surescripts` | **none** | **none** |
| `production-surescripts-worker` | 1 | `production-worker` | `ghcr.io/emrbear/prex-surescripts` | **none** | **none** |
| `saaspass-web` | 1 | `web` | `ghcr.io/emrbear/prex-saaspass` | **none** | **none** |
| `staging-idology-web` | 1 | `web` | `ghcr.io/emrbear/prex-idology` | **none** | **none** |
| `staging-surescripts-web` | 1 | `staging-web` | `ghcr.io/emrbear/prex-surescripts` | **none** | **none** |
| `staging-surescripts-worker` | 1 | `staging-worker` | `ghcr.io/emrbear/prex-surescripts` | **none** | **none** |

> **Critical gap:** Zero CPU or memory requests/limits are defined for any workload in the `prex` namespace. This means Kubernetes cannot make informed scheduling decisions and EKS node sizing will be guesswork. **Resource profiling (e.g., via Kubecost or VPA in recommendation mode) must be completed before EKS node group sizing.**

### 3.2 CronJobs

| Name | Schedule | Notes |
|---|---|---|
| `production-surescripts-directory-full-sync` | `0 0 * * 0` (weekly, Sundays) | Surescripts full directory sync |
| `production-surescripts-directory-nightly-sync` | `0 0 * * 1-5` (Mon–Fri nightly) | Surescripts nightly sync |
| `staging-surescripts-directory-full-sync` | `0 3 * * 6` (weekly, Saturdays) | Staging full sync |
| `staging-surescripts-directory-nightly-sync` | `0 3 * * 1-5` (Mon–Fri nightly) | Staging nightly sync |

### 3.3 Failed Jobs ⚠️

Three Jobs are in **Failed** state with extended durations, indicating pre-existing operational issues:

| Job Name | Status | Age |
|---|---|---|
| `production-surescripts-directory-full-sync-29397600` | Failed | 89 days |
| `production-surescripts-directory-nightly-sync-29373120` | Failed | 106 days |
| `staging-surescripts-directory-nightly-sync-28818900` | Failed | 491 days |

> These should be investigated and resolved independently of the migration. Their presence may indicate connectivity or credential issues with the Surescripts directory service.

### 3.4 Services

| Name | Type | Port | Notes |
|---|---|---|---|
| `cerner-web` | ClusterIP | 80 | Active |
| `idology-web` | ClusterIP | 80 | Active (staging) |
| `production-idology-web` | ClusterIP | 80 | Active (production) |
| `production-surescripts-web` | ClusterIP | 80 | Active |
| `saaspass-web` | ClusterIP | 80 | Active |
| `staging-idology-web` | ClusterIP | 80 | Active |
| `staging-surescripts-web` | ClusterIP | 80 | Active |
| `surescripts-web` | ClusterIP | 80 | **No matching deployment — likely orphaned** |

### 3.5 Ingress Resources

| Name | Host | Ingress Class |
|---|---|---|
| `surescripts-production-ingress` | `surescripts-production.emrbear.com` | `nginx` |
| `surescripts-staging-ingress` | `surescripts-staging.emrbear.com` | `nginx` |

> Cerner, Idology, and Saaspass services have no Ingress defined — they may be accessed via internal cluster routing only, or via the main ingress in another namespace. Confirm routing before migration.

### 3.6 Persistent Volume Claims

None. No stateful storage in this namespace.

### 3.7 Horizontal Pod Autoscalers

None configured.

### 3.8 ConfigMaps

| Name | Notes |
|---|---|
| `cerner-config` | Cerner integration configuration |
| `idology-config` | IDology identity verification config |
| `prex-elasticsearch-config` | ⚠️ Elasticsearch endpoint config — dependency to identify |
| `prex-proxy-config` | ⚠️ Proxy configuration — may reference DO-specific endpoints |
| `saaspass-config` | SaasPass SSO configuration |
| `surescripts-config` | Surescripts production config |
| `surescripts-config-staging` | Surescripts staging config |

### 3.9 Secrets ⚠️ Migration Blockers

| Secret Name | Type | Notes |
|---|---|---|
| `cerner-secrets` | Opaque | Cerner API credentials |
| `github-docker-registry` | `kubernetes.io/dockerconfigjson` | Pull credentials for `ghcr.io` |
| `idology-secrets` | Opaque | IDology API credentials |
| `prex-aws-secrets` | Opaque | **Already contains AWS credentials** — this namespace has an existing AWS integration |
| `prex-postgres-secrets` | Opaque | PostgreSQL connection credentials (production) |
| `prex-postgres-staging-secrets` | Opaque | PostgreSQL connection credentials (staging) |
| `saaspass-secrets` | Opaque | SaasPass credentials |
| `surescripts-connection-cert` | Opaque | **TLS client certificate for Surescripts connectivity** — requires careful migration |
| `surescripts-secrets` | Opaque | Surescripts API credentials (production) |
| `surescripts-staging-secrets` | Opaque | Surescripts API credentials (staging) |

### 3.10 Service Accounts

Default service account only. No custom RBAC.

---

## 4. Ingress Controller

| Property | Current (DOKS) | Target (EKS) |
|---|---|---|
| Controller | ingress-nginx (v2 active, v1 legacy) | ingress-nginx (same) or AWS Load Balancer Controller |
| Service type | `NodePort` (10.245.201.84) | `LoadBalancer` → AWS NLB or ALB |
| TLS termination | Not configured at Ingress level | Add cert-manager + ACM integration |

> Two ingress controller deployments exist (`nginx-ingress-controller-manual` on NodePort 32086/31015, and `nginx-ingress-v2` on NodePort 31184/32662). The v2 controller is the active one. The legacy v1 installation should be decommissioned. On EKS, the recommended approach is to expose ingress-nginx via an AWS Network Load Balancer or use the AWS Load Balancer Controller for native ALB Ingress.

---

## 5. Storage

### 5.1 Storage Classes (Cluster-Wide)

| Name | Provisioner | Reclaim Policy | Volume Binding | Expandable |
|---|---|---|---|---|
| `do-block-storage` (default) | `dobs.csi.digitalocean.com` | Delete | Immediate | Yes |
| `do-block-storage-retain` | `dobs.csi.digitalocean.com` | Retain | Immediate | Yes |
| `do-block-storage-xfs` | `dobs.csi.digitalocean.com` | Delete | Immediate | Yes |
| `do-block-storage-xfs-retain` | `dobs.csi.digitalocean.com` | Retain | Immediate | Yes |

> **All storage classes are DO-specific.** They must be replaced with EKS equivalents using `ebs.csi.aws.com`:
>
> | DO Storage Class | EKS Replacement |
> |---|---|
> | `do-block-storage` | `gp3` (default EKS StorageClass) |
> | `do-block-storage-retain` | Custom `gp3` StorageClass with `reclaimPolicy: Retain` |
> | `do-block-storage-xfs` | Custom `gp3` StorageClass with `fsType: xfs` |
> | `do-block-storage-xfs-retain` | Custom `gp3` StorageClass with `fsType: xfs` + `reclaimPolicy: Retain` |

### 5.2 PVCs in Scope

No PersistentVolumeClaims exist in the `services` or `prex` namespaces. No stateful storage migration is required for these two namespaces specifically. Other namespaces in the cluster (not in scope here) may have PVCs.

---

## 6. Container Image Registries

| Registry | Used By | Migration Action |
|---|---|---|
| `registry.emrbear.com` (self-hosted, in-cluster) | `bear-services`, `bear-x12`, `bear-xero` | **High priority:** This registry runs as a pod in the `services` namespace. It must be migrated to AWS ECR (or kept external) before these workloads can be redeployed. Images must be pushed to ECR and all image references updated. |
| `ghcr.io/emrbear/*` | `trip-form-filler`, all `prex` workloads | No migration required — GHCR is cloud-agnostic. Pull secrets need to be re-provisioned. |
| `nginx:alpine`, `registry:2.7.1` | `bear-services-nginx`, `docker-registry` | Public Docker Hub images — no migration needed. |

> The in-cluster Docker registry (`docker-registry` deployment, exposed at `registry.emrbear.com`) is a **critical dependency and migration blocker**. It stores images used by other services in the cluster. Migration sequence must ensure this registry is replaced or mirrored to ECR before any dependent workloads are redeployed.

---

## 7. External Dependencies Identified

| Dependency | Evidence | Action Required |
|---|---|---|
| **PostgreSQL database** | `prex-postgres-secrets`, `prex-postgres-staging-secrets` | Identify host (likely DO Managed Database). Plan migration to AWS RDS PostgreSQL. |
| **Elasticsearch** | `prex-elasticsearch-config` ConfigMap | Identify host (self-hosted or DO Managed). Plan migration to AWS OpenSearch or self-hosted on EKS. |
| **Surescripts directory service** | CronJobs, `surescripts-connection-cert` | External SaaS — cluster needs outbound connectivity to Surescripts endpoints. TLS client certificate must be re-provisioned in EKS. |
| **Xero API** | `bear-xero` deployment, `xero-config` | External SaaS — ensure outbound IP allowlisting is updated if Xero has IP restrictions. |
| **IDology** | `idology-web` deployments | External SaaS — same IP allowlisting concern. |
| **Cerner** | `cerner-web` deployment | External SaaS — same IP allowlisting concern. |
| **Existing AWS integration** | `prex-aws-secrets` in `prex` namespace | Some AWS service is already being called from this namespace. Identify which service and ensure IAM role/credentials are migrated correctly (prefer IRSA on EKS over static credentials). |

---

## 8. Migration Risk Summary

### 8.1 High Priority (Blockers)

| # | Issue | Namespace | Impact |
|---|---|---|---|
| 1 | **In-cluster Docker registry** hosts images for active workloads | `services` | Cannot redeploy `bear-services`, `bear-x12`, `bear-xero` without migrating images to ECR first |
| 2 | **All Secrets must be migrated** — 16 Opaque secrets across both namespaces | Both | No workload will function without credentials |
| 3 | **Surescripts TLS client certificate** (`surescripts-connection-cert`) | `prex` | Must be re-issued or carefully transferred; likely tied to a specific endpoint/IP |
| 4 | **PostgreSQL database location** unknown | `prex` | If on DO Managed Databases, data migration to RDS must precede app migration |
| 5 | **Storage class replacement** — all DO CSI classes are incompatible with EKS | Cluster-wide | Equivalent EKS StorageClasses must be pre-provisioned |

### 8.2 Medium Priority

| # | Issue | Namespace | Impact |
|---|---|---|---|
| 6 | **No resource requests/limits on `prex` workloads** | `prex` | Cannot right-size EKS node groups; risk of OOMKill or CPU starvation |
| 7 | **No CPU limits on `services` workloads** | `services` | Same concern — limits should be added |
| 8 | **Ingress controller dual-version** (v1 legacy still deployed) | `nginx-ingress` | Decommission v1 before migration to avoid confusion |
| 9 | **Three long-running failed CronJobs** | `prex` | Pre-existing issue; should be resolved before migration to avoid inheriting broken state |
| 10 | **Outbound IP change** for Xero, IDology, Cerner, Surescripts | Both | EKS nodes will have different public IPs — notify external partners if IP allowlisting is in place |
| 11 | **`prex-aws-secrets` uses static AWS credentials** | `prex` | Should be replaced with EKS IRSA (IAM Roles for Service Accounts) |

### 8.3 Low Priority / Housekeeping

| # | Issue | Notes |
|---|---|---|
| 12 | Orphaned `latex-service` ClusterIP in `services` | No deployment backing it — confirm and remove |
| 13 | Orphaned `surescripts-web` ClusterIP in `prex` | No deployment backing it — confirm and remove |
| 14 | No HPAs in either namespace | Consider adding after migration with actual AWS metrics |
| 15 | `prex-proxy-config` may reference DO-specific proxy endpoints | Audit content before migration |

---

## 9. Recommended Migration Approach

1. **Pre-migration (NOW):**
   - Add resource requests/limits to all `prex` workloads and missing limits in `services`
   - Resolve the three failed Surescripts CronJobs
   - Audit `prex-proxy-config` for DO-specific endpoints
   - Identify and confirm PostgreSQL and Elasticsearch locations
   - Contact external partners (Xero, IDology, Cerner, Surescripts) about IP changes

2. **Registry migration:**
   - Create AWS ECR repositories for `bear-services`, `bear-services-hds`, `bear_x12`, `bear-xero`
   - Push all current images from `registry.emrbear.com` to ECR
   - Update deployment manifests to reference ECR
   - Migrate `docker-registry` deployment to ECR (or decommission if ECR fully replaces it)

3. **EKS cluster setup:**
   - Kubernetes version: v1.32 (matches current DOKS version — no version gap)
   - Create three managed node groups: `standard-pool`, `delayed-job`, `monitoring`
   - Reproduce node pool labels/taints for workload affinity
   - Install ingress-nginx v2 with AWS NLB (LoadBalancer service type)
   - Install AWS EBS CSI driver and create equivalent StorageClasses
   - Install cert-manager + ACM integration for TLS

4. **Secrets migration:**
   - Provision all secrets into AWS Secrets Manager
   - Deploy External Secrets Operator to sync into Kubernetes Secrets
   - Replace `prex-aws-secrets` static credentials with IRSA

5. **Workload migration (namespace by namespace):**
   - `services` namespace first (lower external dependency complexity)
   - `prex` namespace second (more external dependencies, failed jobs to resolve)

6. **DNS cutover:**
   - Update DNS for `services.emrbear.com`, `parser.emrbear.com`, `bear-xero.emrbear.com`, `registry.emrbear.com`, `surescripts-production.emrbear.com`, `surescripts-staging.emrbear.com`

---

## 10. Workload Summary

| Namespace | Deployments | CronJobs | Failed Jobs | Services | Ingresses | PVCs | Secrets | ConfigMaps |
|---|---|---|---|---|---|---|---|---|
| `services` | 6 (16 total pods) | 0 | 0 | 8 | 4 | 0 | 6 | 4 |
| `prex` | 9 (13 total pods) | 4 | 3 | 8 | 2 | 0 | 10 | 7 |
| **Total** | **15** | **4** | **3** | **16** | **6** | **0** | **16** | **11** |

---

*Report generated from live cluster data via `kubectl` on 2026-02-20.*
