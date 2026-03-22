# EC2 vs Fargate Cost Analysis — EMR-Bear EKS Migration

**Prepared:** 2026-03-22
**Context:** DigitalOcean → AWS EKS migration, Multi-AZ + Multi-Region DR
**Primary Region:** us-west-2 (co-located with existing AWS IoT, DynamoDB, Bedrock, S3)
**DR Region:** us-east-1 (cold standby)

---

## 1. Current Workload Profile

| Component | Count | Current DO Spec | Notes |
|---|---|---|---|
| Tenant web pods (Puma/Rails) | ~200 | 1-2 replicas per tenant | `bear-app` |
| DelayedJob worker pods | ~167 | 1 replica per tenant | Background processing |
| Infrastructure pods | ~50 | Various | bear-services, x12, xero, trip-form-filler, stats, cron, registry |
| Prex healthcare pods | ~13 | Various | cerner, surescripts, idology, saaspass |
| Monitoring (DaemonSets) | 79 (1/node) | node-exporter, etc. | **Cannot run on Fargate** |
| StatefulSets | 4 | Memcached, Redis, Prometheus | **Cannot use EBS on Fargate** |
| **Total pods** | **~1,141** | | |

### Current DO Node Pools (what we're replacing)

| Pool | Nodes | DO Spec | Total vCPU | Total RAM |
|---|---|---|---|---|
| `standard-pool` | 40 | s-6vcpu-16gb | 240 | 640 GB |
| `delayed-job` | 38 | s-6vcpu-16gb | 228 | 608 GB |
| `monitoring` | 1 | s-2vcpu-4gb | 2 | 4 GB |
| **Total** | **79** | | **470** | **1,252 GB** |

---

## 2. EC2 Cost Breakdown

### 2.1 Instance Mapping (from migration plan)

| Pool | AWS Instance | Spec | Node Count |
|---|---|---|---|
| `standard-pool` | m6i.2xlarge | 8 vCPU / 32 GB | 40 |
| `delayed-job` | m6i.xlarge | 4 vCPU / 16 GB | 38 |
| `monitoring` | t3.medium | 2 vCPU / 4 GB | 1 |

> **Note:** The migration plan oversizes the standard pool (32 GB vs DO's 16 GB). A right-sized
> alternative is discussed in Section 2.3.

### 2.2 EC2 Pricing Tiers (monthly, us-west-2)

| Pricing Model | standard-pool (40x m6i.2xlarge) | delayed-job (38x m6i.xlarge) | monitoring (1x t3.medium) | EKS Control | **Monthly Total** | **Annual Total** |
|---|---|---|---|---|---|---|
| **On-Demand** | $11,213 | $5,326 | $30 | $73 | **$16,642** | **$199,704** |
| **1yr RI (No Upfront)** | $6,920 | $3,287 | $19 | $73 | **$10,299** | **$123,588** |
| **1yr Savings Plan** | $7,849 | $3,728 | $21 | $73 | **$11,671** | **$140,052** |
| **3yr RI (All Upfront)** | $4,480 | $2,128 | $12 | $73 | **$6,693** | **$80,316** |
| **Hybrid: RI standard + Spot delayed-job** | $6,920 | $1,634* | $19 | $73 | **$8,646** | **$103,752** |

*Spot pricing for m6i.xlarge estimated at ~$0.058/hr (70% off on-demand). DelayedJob workers are interruption-tolerant — ideal Spot candidates.

### 2.3 Right-Sized EC2 Alternative

The standard pool uses m6i.2xlarge (32 GB) but DO only had 16 GB per node. If profiling shows 16 GB is sufficient:

| Pool | Instance | Nodes | 1yr RI/mo | 3yr RI/mo |
|---|---|---|---|---|
| `standard-pool` | m6i.xlarge (4 vCPU / 16 GB) | 60* | $5,190 | $3,360 |
| `delayed-job` | m6i.xlarge (4 vCPU / 16 GB) | 38 | $3,287 | $2,128 |
| `monitoring` | t3.medium | 1 | $19 | $12 |
| EKS Control Plane | — | — | $73 | $73 |
| **Total** | | **99** | **$8,569** | **$5,573** |
| **Annual** | | | **$102,828** | **$66,876** |

*60 nodes needed to match 240 vCPU (60 × 4 = 240) from DO's standard pool.

---

## 3. Fargate Cost Breakdown

### 3.1 Fargate Pricing (us-west-2)

| Resource | Rate |
|---|---|
| vCPU | $0.04048/hr |
| Memory (per GB) | $0.004445/hr |

### 3.2 Pod-Level Resource Sizing

| Pod Type | Count | vCPU | Memory | Cost/pod/hr | Monthly Total |
|---|---|---|---|---|---|
| Tenant web (Rails/Puma) | 200 | 1 | 3 GB | $0.05381 | $7,857 |
| DelayedJob workers | 167 | 0.5 | 1 GB | $0.02469 | $3,009 |
| bear-services (+ HDS sidecar) | 1 | 2 | 4 GB | $0.09874 | $72 |
| bear-services-nginx | 1 | 0.5 | 1 GB | $0.02469 | $18 |
| bear-x12 | 2 | 0.5 | 1 GB | $0.02469 | $36 |
| bear-xero | 1 | 0.5 | 1 GB | $0.02469 | $18 |
| trip-form-filler | 3 | 0.5 | 1 GB | $0.02469 | $54 |
| bear-stats + bear-github | 2 | 0.5 | 1 GB | $0.02469 | $36 |
| Prex services | 13 | 0.5 | 1 GB | $0.02469 | $234 |
| **Fargate subtotal** | **390** | | | | **$11,334** |

### 3.3 Components That CANNOT Run on Fargate

| Component | Why | Solution | Est. Monthly Cost |
|---|---|---|---|
| DaemonSets (10 total: node-exporter, etc.) | Fargate doesn't support DaemonSets | EC2 node group + sidecar pattern | $150 (3x t3.medium) |
| Memcached StatefulSet | Fargate doesn't support EBS volumes | ElastiCache Memcached (2 nodes) | $120 |
| Redis StatefulSet | Same — no EBS | ElastiCache Redis (1 node) | $60 |
| Prometheus StatefulSet (50Gi PVC) | Same — no EBS | EC2 node for monitoring OR managed Prometheus | $200 |
| Docker Registry (5Gi mem request) | Can run on Fargate but better to replace | **Use ECR instead** ($0) | $0 |
| **Non-Fargate subtotal** | | | **$530** |

### 3.4 Fargate Total Cost by Pricing Tier

| Pricing Model | Fargate Pods | Non-Fargate Infra | EKS Control | **Monthly Total** | **Annual Total** |
|---|---|---|---|---|---|
| **On-Demand** | $11,334 | $530 | $73 | **$11,937** | **$143,244** |
| **1yr Savings Plan (20% off)** | $9,067 | $530 | $73 | **$9,670** | **$116,040** |
| **3yr Savings Plan (45% off)** | $6,234 | $530 | $73 | **$6,837** | **$82,044** |

### 3.5 Fargate Limitations for This Workload

| Limitation | Impact | Severity |
|---|---|---|
| **No DaemonSets** | 10 DaemonSets (monitoring agents) need EC2 or sidecar refactoring | Medium |
| **No EBS volumes** | Prometheus, Memcached, Redis StatefulSets can't run on Fargate | Medium |
| **No privileged containers** | Some monitoring/debugging tools won't work | Low |
| **1 ENI per pod** | 1,141 pods = 1,141 ENIs; VPC subnet must be /16 or larger | High — plan subnets carefully |
| **Max 4 vCPU / 30 GB per pod** | OK for this workload (no pod needs more) | None |
| **Cold starts** | New pods take 30-60s longer than EC2 (image pull + microVM init) | Low |
| **No node-level SSH** | Cannot SSH into nodes for debugging | Low (use `kubectl exec`) |

---

## 4. Head-to-Head Comparison

### 4.1 Cost Summary Table

| Scenario | Monthly | Annual | vs. Cheapest |
|---|---|---|---|
| EC2 On-Demand | $16,642 | $199,704 | +149% |
| **Fargate On-Demand** | $11,937 | $143,244 | +79% |
| EC2 1yr RI (No Upfront) | $10,299 | $123,588 | +54% |
| EC2 1yr Savings Plan | $11,671 | $140,052 | +75% |
| **Fargate 1yr Savings Plan** | **$9,670** | **$116,040** | +45% |
| EC2 Hybrid (RI + Spot workers) | $8,646 | $103,752 | +30% |
| EC2 Right-sized 1yr RI | $8,569 | $102,828 | +28% |
| **Fargate 3yr Savings Plan** | $6,837 | $82,044 | +2% |
| EC2 3yr RI (All Upfront) | $6,693 | $80,316 | +0.2% |
| **EC2 Right-sized 3yr RI** | **$5,573** | **$66,876** | **Cheapest** |

### 4.2 Total Cost of Ownership (including operational overhead)

| Factor | EC2 | Fargate |
|---|---|---|
| OS patching / AMI updates | You manage (monthly) | AWS manages |
| Node scaling / right-sizing | You manage (Karpenter/CA) | Automatic per-pod |
| Security hardening (CIS benchmarks) | You manage | AWS manages |
| Kubernetes version upgrades (nodes) | You coordinate | AWS handles Fargate platform |
| Monitoring node health | You manage | Not applicable |
| Estimated DevOps time | 0.25-0.5 FTE (~$30-60K/yr) | Near zero |
| **True annual cost (1yr commit)** | **$123,588 + $45K ops = ~$169K** | **$116,040 + $5K ops = ~$121K** |
| **True annual cost (3yr commit)** | **$80,316 + $45K ops = ~$125K** | **$82,044 + $5K ops = ~$87K** |

> **Key insight:** Fargate appears ~30% more expensive on raw compute, but when you factor in
> operational overhead, the gap closes significantly. For a team without dedicated K8s node
> management expertise, Fargate can actually be cheaper in total cost of ownership.

---

## 5. Multi-AZ Architecture Cost

### 5.1 Option A: Preferred Zone + Warm Standby (Andres's preferred, from screenshot)

```
us-west-2a (PRIMARY)                    us-west-2b (STANDBY)
┌─────────────────────────┐            ┌──────────────────────┐
│  Full EKS Cluster       │            │  2-3 Warm Spare      │
│  (all ~1,141 pods)      │            │  Nodes (idle)        │
│                         │            │                      │
│  RDS Primary            │───Multi-AZ──▶ RDS Standby         │
│  (all instances)        │  (auto)    │  (auto-failover)     │
│                         │            │                      │
│  ElastiCache Primary    │            │  ElastiCache Replica  │
└─────────────────────────┘            └──────────────────────┘
```

| Cost Component | Monthly | Annual |
|---|---|---|
| Primary AZ compute (see Section 2 or 3) | (base cost) | (base cost) |
| Warm spare nodes (2-3 × m6i.xlarge RI) | $173 - $260 | $2,076 - $3,120 |
| RDS Multi-AZ standby (doubles RDS compute) | (included in RDS pricing below) | |
| Cross-AZ data transfer | ~$42 | ~$500 |
| **Additional cost over single-AZ** | **~$250/mo** | **~$3,000/yr** |

**AZ Failure RTO:** 2-5 minutes (RDS auto-failover: 60-120s, pods reschedule to standby + autoscaler scales up: 5-15 min for full capacity)
**Data Loss:** 0

### 5.2 Option B: Active-Active 50/50 Multi-AZ (Ramesh's recommendation)

```
us-west-2a (ACTIVE)                     us-west-2b (ACTIVE)
┌─────────────────────────┐            ┌──────────────────────┐
│  50% EKS Pods           │◀──Cross-AZ──▶ 50% EKS Pods        │
│  (~570 pods)            │   traffic   │  (~570 pods)         │
│                         │            │                      │
│  RDS Primary            │───Multi-AZ──▶ RDS Standby         │
│                         │  (auto)    │  (auto-failover)     │
│                         │            │                      │
│  ElastiCache Primary    │◀──repl────▶│  ElastiCache Replica  │
└─────────────────────────┘            └──────────────────────┘
```

| Cost Component | Monthly | Annual |
|---|---|---|
| Compute (same total, split across AZs) | (same base cost) | (same base cost) |
| RDS Multi-AZ standby | (same as Option A) | |
| **Cross-AZ data transfer** | **~$1,667** | **~$20,000** |
| **Additional cost over single-AZ** | **~$1,667/mo** | **~$20,000/yr** |

**AZ Failure RTO:** < 2 minutes (automatic, traffic routes to surviving AZ)
**Data Loss:** 0

### 5.3 Multi-AZ Comparison

| Factor | Option A (Preferred Zone) | Option B (Active-Active) |
|---|---|---|
| Additional annual cost | ~$3,000 | ~$20,000 |
| AZ failure RTO | 2-15 min | < 2 min |
| Cross-AZ latency | None (all traffic in 1 AZ) | 1-2ms (imperceptible) |
| Complexity | Lower | Higher (pod topology constraints) |
| **Recommendation** | **Best value for this workload** | Justified only if < 2 min RTO is mandatory |

> **Andres's assessment is correct:** Option A with 2-3 minute downtime is the right call.
> AZ failures are rare (1-3 per region per year historically), and the $17K/yr savings
> outweighs the ~13 minute RTO difference.

---

## 6. Multi-Region DR Cost

### 6.1 Option A: Cold Standby (Daily Snapshots to us-east-1)

No running compute. Automated daily RDS snapshots copied cross-region.

| Cost Component | Monthly | Annual |
|---|---|---|
| Cross-region snapshot transfer (~500 GB/day incremental × $0.02/GB) | ~$50 | ~$600 |
| Snapshot storage in us-east-1 (~2 TB total) | ~$46 | ~$552 |
| S3 cross-region replication (app data, configs) | ~$20 | ~$240 |
| **Total DR cost** | **~$116** | **~$1,392** |

**Regional Failure RTO:** 3-6 hours (provision EKS, restore RDS from snapshot, deploy pods)
**Data Loss (RPO):** Up to 24 hours (last snapshot)

### 6.2 Option B: Warm Standby (Standby RDS in us-east-1) — Rick's suggestion

Running RDS read replicas cross-region. No EKS compute.

| Cost Component | Monthly | Annual |
|---|---|---|
| RDS cross-region read replicas (matches primary sizing) | ~$2,500* | ~$30,000 |
| Cross-region replication data transfer | ~$200 | ~$2,400 |
| S3 cross-region replication | ~$20 | ~$240 |
| **Total DR cost** | **~$2,720** | **~$32,640** |

*Estimate assumes 4-5 RDS instances (consolidated from 167 tenant DBs). Actual depends on instance sizing.

**Regional Failure RTO:** 1-2 hours (promote RDS replicas, provision EKS, deploy pods)
**Data Loss (RPO):** 1-5 seconds (async replication lag)

### 6.3 Option C: Hybrid — Hot DB + Cold Compute (RECOMMENDED)

Maintain **one small RDS read replica** per database cluster in us-east-1 (not full-size — use smaller instance class). No EKS compute.

| Cost Component | Monthly | Annual |
|---|---|---|
| RDS cross-region read replicas (smaller instance class) | ~$800* | ~$9,600 |
| Cross-region replication data transfer | ~$200 | ~$2,400 |
| S3 cross-region replication | ~$20 | ~$240 |
| **Total DR cost** | **~$1,020** | **~$12,240** |

*Uses db.r6g.large or db.t3.large instead of matching primary instance sizes.

**Regional Failure RTO:** 1-2 hours (promote replicas, scale up, provision EKS, deploy)
**Data Loss (RPO):** 1-5 seconds
**Advantage:** Checks the "multi-region" box for investors with minimal RPO, at 1/3 the cost of full-size replicas.

---

## 7. Total Annual Cost — All Scenarios Combined

### Compute + Multi-AZ (Preferred Zone) + Multi-Region DR

| Compute Choice | Compute/yr | Multi-AZ | DR (Cold) | DR (Hybrid) | **Total w/ Cold DR** | **Total w/ Hybrid DR** |
|---|---|---|---|---|---|---|
| EC2 On-Demand | $199,704 | $3,000 | $1,392 | $12,240 | $204,096 | $214,944 |
| EC2 1yr RI | $123,588 | $3,000 | $1,392 | $12,240 | $127,980 | $138,828 |
| EC2 3yr RI | $80,316 | $3,000 | $1,392 | $12,240 | $84,708 | $95,556 |
| EC2 Right-sized 3yr RI | $66,876 | $3,000 | $1,392 | $12,240 | $71,268 | $82,116 |
| EC2 Hybrid (RI + Spot) | $103,752 | $3,000 | $1,392 | $12,240 | $108,144 | $118,992 |
| Fargate On-Demand | $143,244 | $3,000 | $1,392 | $12,240 | $147,636 | $158,484 |
| Fargate 1yr SP | $116,040 | $3,000 | $1,392 | $12,240 | $120,432 | $131,280 |
| Fargate 3yr SP | $82,044 | $3,000 | $1,392 | $12,240 | $86,436 | $97,284 |

### Including Estimated Operational Overhead

| Scenario | Infra/yr | Ops Cost/yr | **True Total/yr** |
|---|---|---|---|
| EC2 1yr RI + Cold DR | $127,980 | ~$45,000 | **~$173,000** |
| EC2 1yr RI + Hybrid DR | $138,828 | ~$45,000 | **~$184,000** |
| EC2 3yr RI + Cold DR | $84,708 | ~$45,000 | **~$130,000** |
| EC2 3yr RI + Hybrid DR | $95,556 | ~$45,000 | **~$141,000** |
| EC2 Right-sized 3yr + Cold DR | $71,268 | ~$45,000 | **~$116,000** |
| **Fargate 1yr SP + Cold DR** | $120,432 | ~$5,000 | **~$125,000** |
| **Fargate 1yr SP + Hybrid DR** | $131,280 | ~$5,000 | **~$136,000** |
| **Fargate 3yr SP + Cold DR** | $86,436 | ~$5,000 | **~$91,000** |
| Fargate 3yr SP + Hybrid DR | $97,284 | ~$5,000 | **~$102,000** |

---

## 8. AZ Failure Frequency — Historical Context

| Year | Notable AWS AZ/Region Incidents | Region |
|---|---|---|
| 2023 | Multiple us-east-1 incidents; us-west-2 incident (Sep) | us-east-1, us-west-2 |
| 2024 | us-east-1 Kinesis failure (Jul, ~7 hrs) | us-east-1 |
| 2025 | eu-north-1 Stockholm (Feb); us-east-1 (Oct, ~15 hrs); us-west-2 (Oct) | Multiple |

**Key takeaway:**
- **Full AZ failures:** ~1-3 per region per year, lasting minutes to hours
- **Full region failures:** Extremely rare (~once every few years, typically us-east-1)
- **us-west-2 (Oregon):** Historically more stable than us-east-1, fewer major incidents
- **Conclusion:** The "Preferred Zone + Warm Standby" architecture with 2-5 min AZ failover RTO is well-justified. The ~$17K/yr savings over active-active is worth it given AZ failures happen ~1-3 times/year.

---

## 9. Recommendation

### Best Architecture: Preferred Zone + Warm Standby (Multi-AZ) with Hybrid DR

```
us-west-2a (PRIMARY)                    us-west-2b (STANDBY)
┌─────────────────────────┐            ┌──────────────────────┐
│  Full EKS Cluster       │            │  2-3 Warm Spare      │
│  EC2 or Fargate         │            │  Nodes (autoscale)   │
│                         │            │                      │
│  RDS Primary            │───Multi-AZ──▶ RDS Standby         │
│  ElastiCache Primary    │            │  ElastiCache Replica  │
└─────────────────────────┘            └──────────────────────┘

us-east-1 (COLD DR)
┌──────────────────────────────────────┐
│  RDS Read Replicas (small instances) │
│  No EKS (provision on demand)        │
│  S3 cross-region replication         │
│  Daily snapshot backups              │
└──────────────────────────────────────┘
```

### Best Compute Choice: Depends on Team Capacity

#### If you have (or will hire) dedicated K8s/DevOps capacity:
**EC2 with 1yr Reserved Instances + Spot for delayed-job workers**

| Component | Annual |
|---|---|
| EC2 compute (RI + Spot) | $103,752 |
| Multi-AZ (preferred zone) | $3,000 |
| Hybrid DR (us-east-1) | $12,240 |
| Ops overhead (~0.3 FTE) | $45,000 |
| **Total** | **~$164,000/yr** |

**Pros:** Most cost-effective on paper, full control, Spot savings on workers
**Cons:** Requires ongoing node management expertise, OS patching, AMI updates

#### If you prefer minimal operational burden (RECOMMENDED for lift-and-shift):
**Fargate with 1yr Compute Savings Plan**

| Component | Annual |
|---|---|
| Fargate compute (1yr SP) | $116,040 |
| Non-Fargate infra (ElastiCache, monitoring EC2) | $6,360 |
| Multi-AZ (preferred zone) | $3,000 |
| Hybrid DR (us-east-1) | $12,240 |
| Ops overhead (minimal) | $5,000 |
| **Total** | **~$143,000/yr** |

**Pros:** Zero node management, auto-scaling per pod, simpler operations, faster time-to-migrate
**Cons:** Need to refactor DaemonSets to sidecars, VPC subnet sizing for 1,141 ENIs, no EBS

#### Best value long-term (3yr commitment):
**Fargate with 3yr Compute Savings Plan**

| Component | Annual |
|---|---|
| Fargate compute (3yr SP) | $82,044 |
| Non-Fargate infra | $6,360 |
| Multi-AZ | $3,000 |
| Hybrid DR | $12,240 |
| Ops overhead | $5,000 |
| **Total** | **~$109,000/yr** |

### Decision Matrix

| Factor | EC2 | Fargate | Winner |
|---|---|---|---|
| Raw compute cost (1yr) | $123,588 | $116,040 | **Fargate** (surprisingly) |
| Raw compute cost (3yr) | $80,316 | $82,044 | EC2 (barely) |
| Operational overhead | ~$45K/yr | ~$5K/yr | **Fargate** |
| Total cost of ownership | ~$164K/yr | ~$143K/yr | **Fargate** |
| Time to migrate | Longer (node config) | Faster (Fargate profiles) | **Fargate** |
| DaemonSet support | Yes | No | EC2 |
| EBS/StatefulSet support | Yes | No (EFS only) | EC2 |
| Debugging/SSH access | Full | Limited | EC2 |
| Spot instance savings | Yes (workers) | No | EC2 |
| Auto-scaling granularity | Node-level | Pod-level | **Fargate** |
| **Overall for lift-and-shift** | Good | **Better** | **Fargate** |

---

## 10. Practical Migration Path

### If choosing Fargate:

1. **Mixed compute strategy:** Fargate for all stateless pods (~95% of workload), small EC2 managed node group (2-3 nodes) for monitoring DaemonSets
2. **Replace in-cluster stateful services:** Memcached → ElastiCache, Redis → ElastiCache, Prometheus → Amazon Managed Prometheus or EC2 node
3. **Fargate profiles:** One per namespace pattern (tenant namespaces, services, prex, monitoring)
4. **VPC planning:** /16 CIDR minimum to accommodate 1,141+ ENIs across 2 AZs
5. **Resource requests mandatory:** Every pod MUST have CPU/memory requests defined (Fargate requires this)

### If choosing EC2:

1. Use Karpenter (not Cluster Autoscaler) for intelligent node provisioning
2. Standard pool: 1yr RI (committed baseline), Karpenter on-demand for burst
3. Delayed-job pool: Spot instances with on-demand fallback
4. Consider Graviton (m7g) instances for ~20% better price/performance (requires ARM image builds)

---

## 11. RDS Cost Estimate (Both Architectures Need This)

| Component | Instance | Multi-AZ Monthly | Annual |
|---|---|---|---|
| Primary MariaDB (tenant DBs) | db.r6g.2xlarge | ~$1,800 | ~$21,600 |
| Prex PostgreSQL (prod) | db.r6g.large | ~$400 | ~$4,800 |
| Prex PostgreSQL (staging) | db.t3.medium | ~$140 | ~$1,680 |
| **RDS subtotal** | | **~$2,340** | **~$28,080** |
| DR replicas in us-east-1 (small) | db.r6g.large × 2 + db.t3.medium | ~$800 | ~$9,600 |

> Note: RDS cost is the same regardless of EC2 vs Fargate compute choice.

---

## 12. Grand Total Estimate

### Recommended: Fargate 1yr SP + Preferred Zone + Hybrid DR

| Line Item | Monthly | Annual |
|---|---|---|
| Fargate compute (1yr Savings Plan) | $9,670 | $116,040 |
| ElastiCache (Memcached + Redis) | $180 | $2,160 |
| EC2 monitoring nodes (3x t3.medium) | $91 | $1,092 |
| RDS Primary (Multi-AZ) | $2,340 | $28,080 |
| RDS DR replicas (us-east-1) | $800 | $9,600 |
| EKS control plane | $73 | $876 |
| Multi-AZ warm spare nodes | $173 | $2,076 |
| Cross-region data transfer | $250 | $3,000 |
| NAT Gateway (2 AZs) | $130 | $1,560 |
| Application Load Balancer | $50 | $600 |
| ECR storage + transfer | $50 | $600 |
| Route 53 + health checks | $30 | $360 |
| **Infrastructure Total** | **$13,837** | **$166,044** |
| Operational overhead (minimal) | $417 | $5,000 |
| **Grand Total** | **~$14,254** | **~$171,044** |

### Alternative: EC2 1yr RI + Spot Workers + Preferred Zone + Hybrid DR

| Line Item | Monthly | Annual |
|---|---|---|
| EC2 compute (RI + Spot) | $8,646 | $103,752 |
| ElastiCache (Memcached + Redis) | $180 | $2,160 |
| RDS Primary (Multi-AZ) | $2,340 | $28,080 |
| RDS DR replicas (us-east-1) | $800 | $9,600 |
| EKS control plane | $73 | $876 |
| Multi-AZ warm spare nodes | $173 | $2,076 |
| Cross-region data transfer | $250 | $3,000 |
| NAT Gateway (2 AZs) | $130 | $1,560 |
| Application Load Balancer | $50 | $600 |
| ECR storage + transfer | $50 | $600 |
| Route 53 + health checks | $30 | $360 |
| **Infrastructure Total** | **$12,722** | **$152,664** |
| Operational overhead (~0.3 FTE) | $3,750 | $45,000 |
| **Grand Total** | **~$16,472** | **~$197,664** |

---

*Pricing based on publicly available AWS rates as of March 2026. Actual costs may vary based on usage patterns, data transfer volumes, and negotiated discounts. All prices are for us-west-2 (Oregon). Recommend validating with AWS Pricing Calculator before finalizing.*

*Sources: [AWS Fargate Pricing](https://aws.amazon.com/fargate/pricing/), [EC2 On-Demand Pricing](https://aws.amazon.com/ec2/pricing/on-demand/), [EC2 Instance Comparison (Vantage)](https://instances.vantage.sh/), [RDS Pricing](https://aws.amazon.com/rds/pricing/), [EKS Pricing](https://aws.amazon.com/eks/pricing/), [Compute Savings Plans](https://aws.amazon.com/savingsplans/compute-pricing/), [Rafay EC2 vs Fargate Cost Comparison](https://rafay.co/ai-and-cloud-native-blog/ec2-vs-fargate-for-amazon-eks-a-cost-comparison/)*
