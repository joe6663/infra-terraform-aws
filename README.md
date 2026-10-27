# Infrastructure: AWS EKS, Karpenter, and GitOps Cluster Config

A multi-environment infrastructure repository combining **Terraform (IaC)** for provisioning AWS resources and **GitOps Kubernetes configurations** for cluster add-ons, RBAC, and Karpenter node autoscaling.

## Architecture

<img width="1024" height="559" alt="eks-cluster" src="https://github.com/user-attachments/assets/6a4b5ce4-06c6-4bd8-be87-465af29214bb" />


---

## Repository Architecture & Directory Structure

The repository is structured into two primary top-level domains:
1. `gitops-cluster-config/`: Declarative Kubernetes manifests separated by cluster environment (`dev`, etc.).
2. `infra-terraform-aws/`: Modular Terraform definitions supporting multi-environment deployments (`dev`, `staging`, etc.).

```
infrastructure/
├── gitops-cluster-config/
│   └── clusters/
│       └── dev/                              # Dev cluster declarative manifests
│           ├── karpenter/
│           │   ├── karpenter-app.yaml        # Karpenter ArgoCD Application / deployment
│           │   └── values.yaml               # Helm chart configuration values for Karpenter
│           ├── nodepools/
│           │   ├── ec2nodeclass.yaml         # Karpenter EC2NodeClass (AWS AMIs, subnets, SGs)
│           │   └── nodepool-app.yaml         # Karpenter NodePool definitions (instance types, limits)
│           └── rbac/
│               └── dev-namespaced-rbac.yaml  # Namespace-specific RBAC roles and bindings
│
└── infra-terraform-aws/
    ├── environments/                         # Environment root modules (calling reusable modules)
    │   ├── dev/
    │   │   ├── eks/                          # Dev cluster Terraform configuration
    │   │   └── eks-addons/                   # Dev cluster add-ons configuration
    │   └── staging/
    │       ├── eks/                          # Staging cluster Terraform configuration
    │       └── eks-addons/                   # Staging cluster add-ons configuration
    │
    └── modules/                              # Reusable Terraform core modules
        ├── eks/                              # Core EKS module
        │   ├── data.tf                       # AWS data sources (caller, VPC, subnets)
        │   ├── encryption_key.tf             # KMS CMK key for secret envelope encryption
        │   ├── main.tf                       # EKS cluster control plane definition
        │   ├── outputs.tf                    # Cluster endpoints, OIDC provider, CA data
        │   ├── role.tf                       # IAM roles for cluster control plane
        │   └── variables.tf                  # EKS module input variables
        │
        └── eks-addons/                       # Core Add-ons & Controllers module
            ├── data.tf                       # OIDC and remote state data lookups
            ├── ebs-csi-addons.tf             # AWS EBS CSI driver managed add-on
            ├── helm-bootstrap.tf             # Helm providers and chart bootstraps
            ├── irsa-role.tf                  # IRSA IAM roles for Kubernetes service accounts
            ├── karpenter.tf                  # Karpenter controller IAM, SQS queues, EventBridge
            └── variables.tf                  # Add-ons module input variables
```

---

## Component Breakdown

### 1. Terraform Modules (`infra-terraform-aws/modules/`)

Reusable, modular components consumed by each environment:

* **`modules/eks/`**:
  * Provisions the Amazon EKS cluster control plane.
  * Creates dedicated KMS Customer Managed Keys (CMK) for native envelope encryption of Kubernetes Secrets (`encryption_key.tf`).
  * Configures EKS service roles, VPC networking, security groups, and endpoint access.
  * Outputs the cluster endpoint, TLS certificate authority, and OIDC issuer ARN.

* **`modules/eks-addons/`**:
  * Deploys the Amazon EBS CSI driver via EKS managed add-ons.
  * Configures IAM Roles for Service Accounts (IRSA) mapping AWS IAM policies to in-cluster service accounts.
  * Configures AWS resources required for **Karpenter**:
    * Karpenter controller IAM role with IRSA trust policies.
    * Node instance profile & IAM role (`KarpenterNodeRole`).
    * SQS interruption queues and EventBridge rules for node termination and Spot interruption notices.
  * Manages initial Helm chart releases via `helm-bootstrap.tf`.

### 2. Environment Root Modules (`infra-terraform-aws/environments/`)

Each environment (`dev`, `staging`) instantiates the shared modules with environment-specific parameters (cluster version, VPC IDs, CIDRs, tags, and scaling parameters).

* **`environments/<env>/eks/`**: Deploys the core EKS control plane.
* **`environments/<env>/eks-addons/`**: Connects to the provisioned EKS cluster and deploys add-ons, controllers, and IAM dependencies.

### 3. GitOps Cluster Configurations (`gitops-cluster-config/`)

Manages Kubernetes resources and custom resources (CRDs) declaratively for each cluster environment:

* **`clusters/<env>/karpenter/`**:
  * `karpenter-app.yaml`: GitOps / ArgoCD application definition or manifest deployment for the Karpenter controller.
  * `values.yaml`: Helm values customizing Karpenter controller replicas, resource requests/limits, log levels, and cluster details.
* **`clusters/<env>/nodepools/`**:
  * `ec2nodeclass.yaml`: AWS-specific node configuration (subnet selector tags, security group tags, AMIs, instance storage).
  * `nodepool-app.yaml`: Karpenter capacity rules (Spot vs. On-Demand preference, instance families, disruption budgets, and consolidation policies).
* **`clusters/<env>/rbac/`**:
  * `dev-namespaced-rbac.yaml`: Roles, ClusterRoles, and RoleBindings enforcing least privilege for developers and CI/CD service accounts.

---

## Prerequisites

* [Terraform](https://www.terraform.io/) `>= 1.5.0`
* [AWS CLI](https://aws.amazon.com/cli/) `>= 2.0`
* [kubectl](https://kubernetes.io/docs/tasks/tools/)
* [Helm](https://helm.sh/) `>= 3.0`
* AWS credentials configured with administrative permissions for VPC, IAM, EKS, KMS, and SQS.

---

## Deployment Workflow

Deployments follow a staged sequence: deploy cluster infrastructure first, provision add-ons second, and apply GitOps manifests last.

### Step 1: Provision the EKS Cluster

Navigate to the target environment's EKS directory (e.g., `dev`):

```bash
cd infra-terraform-aws/environments/dev/eks/
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 2: Configure Local `kubectl` Context

Connect your local terminal to the newly created EKS cluster:

```bash
aws eks update-kubeconfig --region <aws-region> --name <cluster-name>
kubectl get nodes
```

### Step 3: Deploy EKS Add-ons & Karpenter AWS Infrastructure

Provision the add-ons and Karpenter AWS infrastructure:

```bash
cd ../eks-addons/
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 4: Apply GitOps Cluster Configurations

Apply the Kubernetes manifests for the target environment (or allow your GitOps controller like ArgoCD / Flux to sync):

```bash
# From the repository root

# 1. Apply environment RBAC policies
kubectl apply -f gitops-cluster-config/clusters/dev/rbac/dev-namespaced-rbac.yaml

# 2. Deploy Karpenter application (if deploying directly)
kubectl apply -f gitops-cluster-config/clusters/dev/karpenter/karpenter-app.yaml

# 3. Apply Karpenter EC2NodeClass and NodePool CRDs
kubectl apply -f gitops-cluster-config/clusters/dev/nodepools/ec2nodeclass.yaml
kubectl apply -f gitops-cluster-config/clusters/dev/nodepools/nodepool-app.yaml
```

---

## Verification & Troubleshooting

### Add-ons and Karpenter Health

```bash
# Check managed EKS add-ons
aws eks list-addons --cluster-name <cluster-name>

# Inspect Karpenter controller pod status
kubectl get pods -n karpenter
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter
```

### NodePool and NodeClass Inspection

```bash
# Inspect NodePool and NodeClass status
kubectl get nodepool
kubectl describe nodepool default
kubectl get ec2nodeclass

# Watch Karpenter provision nodes dynamically
kubectl get nodes -w --show-labels
```

---

## Teardown Procedure

To avoid resource leakage or dangling dependencies, destroy resources in reverse order:

1. **Delete Dynamic Nodes & GitOps Resources:**
   ```bash
   kubectl delete -f gitops-cluster-config/clusters/dev/nodepools/nodepool-app.yaml
   kubectl delete -f gitops-cluster-config/clusters/dev/nodepools/ec2nodeclass.yaml
   kubectl delete -f gitops-cluster-config/clusters/dev/rbac/dev-namespaced-rbac.yaml
   ```

2. **Destroy EKS Add-ons:**
   ```bash
   cd infra-terraform-aws/environments/dev/eks-addons/
   terraform destroy -auto-approve
   ```

3. **Destroy EKS Cluster Infrastructure:**
   ```bash
   cd ../eks/
   terraform destroy -auto-approve
   ```
