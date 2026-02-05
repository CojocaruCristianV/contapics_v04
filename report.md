# Raport: Deployment în Cloud pentru Aplicația Contapics

**Student:** Cristian Cojocaru  
**Data:** Februarie 2026  
**Versiune aplicație:** Contapics v0.4 (db, backend, frontend)

---

## 1. Infrastructura de Calcul

### 1.1 Prezentare Generală

Aplicația Contapics a fost deployată pe **Amazon Web Services (AWS)** folosind serviciul **Elastic Kubernetes Service (EKS)**. Această arhitectură cloud-native oferă scalabilitate, reziliență și ușurință în management.

### 1.2 Resurse Cloud Utilizate

| Serviciu AWS | Rol | Configurare |
|--------------|-----|-------------|
| **EKS** | Orchestrare containere | Cluster Kubernetes v1.30 |
| **EC2** | Node-uri worker | 3x t3.small (scalabil 1-4) |
| **VPC** | Rețea izolată | CIDR 10.0.0.0/16, 3 AZ-uri |
| **ECR** | Registry containere | 2 repository-uri (backend, frontend) |
| **ALB** | Load Balancer | Application Load Balancer via Ingress |
| **EBS** | Stocare persistentă | gp2, 10Gi pentru PostgreSQL |

### 1.3 Arhitectura C4 Model

#### Nivel 1: Context Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        UTILIZATORI                              │
│                    (Administratori sistem)                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CONTAPICS SYSTEM                            │
│                                                                 │
│  Aplicație web pentru management utilizatori și companii        │
│  Deployată pe AWS EKS                                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SISTEME EXTERNE                              │
│  - AWS IAM (autentificare)                                      │
│  - AWS ECR (imagini container)                                  │
│  - Prometheus/Grafana (monitorizare)                            │
└─────────────────────────────────────────────────────────────────┘
```

#### Nivel 2: Container Diagram

```
┌────────────────────── AWS EKS Cluster ──────────────────────────┐
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   FRONTEND   │--->│   BACKEND    │--->│  POSTGRESQL  │       │
│  │   (Vue.js)   │    │ (Spring Boot)│    │   Database   │       │
│  │   Nginx      │    │   Port 8080  │    │   Port 5432  │       │
│  │   Port 80    │    │              │    │              │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│         │                   │                    │              │
│         │                   │                    │              │
│         ▼                   ▼                    ▼              │
│  ┌──────────────────────────────────────────────────────┐       │
│  │              AWS Application Load Balancer           │       │
│  │   - frontend.contapics.local                         │       │
│  │   - backend.contapics.local                          │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                 │
│  ┌──────────────────── Monitoring Stack ────────────────────┐   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────────┐  │   │
│  │  │ Prometheus │  │  Grafana   │  │ Postgres Exporter  │  │   │
│  │  └────────────┘  └────────────┘  └────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 1.4 Configurarea Accesului

Accesul la cluster este configurat pe mai multe niveluri:

**IAM Roles pentru Service Accounts (IRSA):**

- `contapics-ebs-csi` - permite EBS CSI Driver să provizioneze volume
- `contapics-alb-controller` - permite ALB Controller să creeze Load Balancere

**Ingress Configuration:**

- `frontend.contapics.local` → Frontend Service (port 80)
- `backend.contapics.local` → Backend Service (port 8080)
- `grafana.contapics.local` → Grafana Dashboard

### 1.5 Considerente de Scalabilitate

| Componentă | Scalare Curentă | Scalare Posibilă |
|------------|-----------------|------------------|
| **Node-uri EKS** | 3 noduri t3.small | Auto-scaling 1-4 noduri |
| **Backend Pods** | 1 replica | HPA până la 10 replici |
| **Frontend Pods** | 1 replica | HPA până la 5 replici |
| **PostgreSQL** | 1 replica | Read replicas cu AWS RDS |

**Mecanisme de scalare disponibile:**

1. **Cluster Autoscaler** - scalează automat nodurile EKS
2. **Horizontal Pod Autoscaler (HPA)** - scalează pod-urile pe baza CPU/Memory
3. **Vertical Pod Autoscaler (VPA)** - ajustează resursele per pod

### 1.6 Estimare Costuri (Pricing)

| Resursă | Specificații | Cost Estimat/Lună |
|---------|--------------|-------------------|
| **EKS Control Plane** | 1 cluster | ~$73 |
| **EC2 (t3.small x2)** | 2 vCPU, 2GB RAM fiecare | ~$30 |
| **NAT Gateway** | 1 gateway | ~$32 |
| **ALB** | 2 load balancere | ~$35 |
| **EBS Storage** | 10Gi gp2 | ~$1 |
| **ECR** | <1GB storage | ~$0.10 |
| **Data Transfer** | Estimat 10GB | ~$1 |
| **TOTAL** | | **~$172/lună** |

### 1.7 Costuri Actuale (Pricing)

| Serviciu AWS | Cost 2 zile | Estimare lunară |
|--------------|-------------|-----------------|
| EKS          | $2.72       | $40.80          |
| EC2 - Other  | $0.29       | $4.35           |
| ELB          | $0.14       | $2.10           |
| EC2 Compute  | $0.13       | $1.95           |
| VPC          | $0.10       | $1.50           |
| **Total**    | **$3.38**   | **$50.70**      |

**Alternative de cost mai redus:**

1. **Fargate** în loc de EC2 - pay-per-use, fără management noduri
2. **Spot Instances** - reducere până la 90% pentru workloads tolerante
3. **Single AZ deployment** - elimină costul NAT Gateway redundant

---

## 2. Infrastructure as Code (IaC)

### 2.1 Soluții IaC Utilizate

| Instrument | Scop | Fișiere |
|------------|------|---------|
| **Terraform** | Provizionare infrastructură AWS | `terraform-eks/*.tf` |
| **Helm** | Packaging aplicație Kubernetes | `contapics-chart/` |
| **Ansible** | Orchestrare deployment | `ansible-eks/playbooks/` |

### 2.2 Structura Terraform

```
terraform-eks/
├── main.tf          # Provider configuration
├── vpc.tf           # VPC cu 3 AZ-uri, subnets publice/private
├── eks.tf           # Cluster EKS și node groups
├── ecr.tf           # Repository-uri pentru imagini Docker
├── iam.tf           # IRSA pentru EBS CSI și ALB Controller
├── variables.tf     # Variabile configurabile
└── outputs.tf       # Outputs pentru scripts
```

**Exemplu configurare EKS (eks.tf):**

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 4
      desired_size = 3
      instance_types = ["t3.small"]
    }
  }

  enable_irsa = true
}
```

### 2.3 Structura Helm Chart

```
contapics-chart/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── backend-deployment.yaml
    ├── frontend-deployment.yaml
    ├── postgres-deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── frontend-configmap.yaml
    ├── db-secret.yaml
    ├── pvc.yaml
    ├── backend-servicemonitor.yaml
    └── postgres-exporter-*.yaml
```

### 2.4 Utilitatea Soluțiilor IaC

**Exemplu 1: Reproductibilitate cu Terraform**

Provizionarea clusterului EKS cu Terraform oferă avantaje semnificative față de `eksctl`:

- **Versionare** - toată infrastructura este în Git
- **Plan/Apply** - vezi exact ce se va schimba înainte de aplicare
- **Module reutilizabile** - VPC, EKS, IAM sunt module separate

```bash
# O singură comandă recreează întreaga infrastructură
terraform apply -auto-approve
```

**Exemplu 2: Deployment consistent cu Helm**

Helm permite deployment-uri consistente și rollback ușor:

```bash
# Upgrade aplicație cu noi valori
helm upgrade contapics-app ./contapics-chart \
  --set backend.replicas=3 \
  --set frontend.backendUrl="http://backend.contapics.local/api"

# Rollback instant la versiunea anterioară
helm rollback contapics-app 1
```

**Exemplu 3: Automatizare cu Ansible**

Ansible orchestrează întreg procesul de deployment:

```yaml
# deploy_all.yml - un singur playbook pentru tot
- import_playbook: push_images.yml
- import_playbook: cluster_setup.yml
- import_playbook: install_monitoring.yml
- import_playbook: deploy_app.yml
```

### 2.5 Provocări și Downsides IaC

**Provocare 1: Compatibilitate versiuni module Terraform**

Modulul `terraform-aws-modules/eks/aws` a suferit schimbări majore între versiunile 19 și 20:

- Versiunea 19: folosea `aws_eks_cluster` direct
- Versiunea 20: folosește `enable_cluster_creator_admin_permissions`

Soluție: Fixarea versiunii în `main.tf`:

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"  # Pin la major version
}
```

**Provocare 2: State management Terraform**

Terraform state-ul local poate cauza probleme în echipă:

- State corruption la modificări concurente
- Pierderea state-ului = infrastructură "orphaned"

Soluție recomandată: S3 backend cu DynamoDB locking:

```hcl
terraform {
  backend "s3" {
    bucket         = "contapics-terraform-state"
    key            = "eks/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
  }
}
```

**Provocare 3: Secrets în Helm values**

Parola bazei de date este vizibilă în `values.yaml`:

```yaml
postgres:
  password: init1234  # ⚠️ Secret în plaintext!
```

Soluție: Utilizare External Secrets Operator sau AWS Secrets Manager:

```yaml
# Cu External Secrets
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
spec:
  secretStoreRef:
    name: aws-secrets-manager
  target:
    name: db-secret
  data:
    - secretKey: password
      remoteRef:
        key: contapics/db-password
```

---

## 3. Observabilitate (Monitorizare)

### 3.1 Stack de Monitorizare

Am implementat **kube-prometheus-stack** care include:

| Componentă | Rol | Acces |
|------------|-----|-------|
| **Prometheus** | Colectare și stocare metrici | Port 9090 |
| **Grafana** | Vizualizare dashboard-uri | http://grafana.contapics.local |
| **Alertmanager** | Gestionare alerte | Port 9093 |
| **Node Exporter** | Metrici sistem | Port 9100 |
| **Postgres Exporter** | Metrici PostgreSQL | Port 9187 |

### 3.2 Expunerea Metricilor din Backend

Backend-ul Spring Boot expune metrici Prometheus prin **Micrometer**:

**Dependențe (pom.xml):**

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

**Configurare (application.yaml):**

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
  endpoint:
    prometheus:
      enabled: true
```

**Endpoint metrici:** `http://backend:8080/api/actuator/prometheus`

### 3.3 ServiceMonitor pentru Prometheus

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: backend
  namespace: monitoring
  labels:
    release: prometheus-stack
spec:
  selector:
    matchLabels:
      app: backend
  endpoints:
    - port: http
      path: /actuator/prometheus
      interval: 30s
  namespaceSelector:
    matchNames:
      - default
```

### 3.4 Dashboard Grafana

Am configurat dashboard-uri pentru:

**1. Metrici Cluster:**

- CPU usage per node și per pod
- Memory usage și pressure
- Pod-uri running/pending/failed
- Network I/O

**2. Metrici Aplicație:**

- Request rate (requests/second)
- Response time (latency p50, p95, p99)
- HTTP status codes distribution (200, 4xx, 5xx)
- JVM memory și garbage collection

**3. Metrici Database (via Postgres Exporter):**

- Conexiuni active
- Queries per second
- Cache hit ratio
- Table sizes

**Exemple de queries PromQL:**

```promql
# Request rate pentru backend
rate(http_server_requests_seconds_count{application="backend"}[5m])

# Latency p95
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{application="backend"}[5m]))

# Error rate
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) 
/ sum(rate(http_server_requests_seconds_count[5m])) * 100
```

### 3.5 Configurare Alerte

Exemple de alerte configurate:

```yaml
groups:
  - name: contapics-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) 
          / sum(rate(http_server_requests_seconds_count[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is above 5% for 5 minutes"

      - alert: PodNotReady
        expr: kube_pod_status_ready{condition="false"} == 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod not ready"

      - alert: HighMemoryUsage
        expr: |
          container_memory_usage_bytes{container!=""} 
          / container_spec_memory_limit_bytes > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
```

---

## 4. Concluzii

### 4.1 Ce a Mers Bine

1. **Terraform pentru infrastructură** - Reproductibilitate 100%, infrastructura poate fi recreată în ~20 minute

2. **Helm pentru aplicație** - Upgrade-uri și rollback-uri simple, configurare centralizată în `values.yaml`

3. **IRSA pentru permisiuni** - Securitate îmbunătățită, fără credențiale hardcodate în pods

4. **Prometheus + Grafana** - Vizibilitate completă asupra sistemului, alerting proactiv

5. **ALB Ingress Controller** - Management automat al Load Balancer-elor AWS

### 4.2 Ce Poate Fi Îmbunătățit

1. **Secrets Management** - Migrare de la Kubernetes Secrets la AWS Secrets Manager cu External Secrets Operator

2. **GitOps cu ArgoCD** - Deployment continuu bazat pe Git, nu pe comenzi manuale Helm

3. **Network Policies** - Izolare rețea între namespace-uri și pods

4. **Pod Security Standards** - Implementare policies pentru containere non-root

5. **Backup Database** - Migrare la AWS RDS cu automated backups sau implementare Velero

### 4.3 Integrare în Mediu Productiv

Pentru un mediu de producție, recomand:

**CI/CD Pipeline (GitHub Actions):**

```yaml
name: Deploy to EKS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-central-1

      - name: Login to ECR
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build and push images
        run: |
          docker build -t backend ./backend
          docker tag backend:latest $ECR_REGISTRY/backend:${{ github.sha }}
          docker push $ECR_REGISTRY/backend:${{ github.sha }}

      - name: Deploy to EKS
        run: |
          aws eks update-kubeconfig --name contapics
          helm upgrade --install contapics-app ./contapics-chart \
            --set backend.image.tag=${{ github.sha }}
```

### 4.4 Posibile Modificări și Impact

| Modificare | Impact Infrastructură | Efort |
|------------|----------------------|-------|
| Adăugare File Storage (S3) | + IAM Role, + SDK în backend | Mediu |
| Adăugare OCR Service | + Pod nou, + ServiceMonitor | Mediu |
| Migrare la RDS | - PostgreSQL pod, + Terraform RDS | Mare |
| Multi-region deployment | x2 infrastructură, + Route53 | Foarte Mare |
| Kubernetes 1.31 upgrade | Test compatibility, rolling update | Mic |
