# End-to-End Containerized Voting App on AWS with Terraform & GitHub Actions

A production-grade, highly available voting application deployed on AWS using Terraform (IaC) and an automated multi-environment CI/CD pipeline powered by GitHub Actions.

---

## 🏗️ Architecture Overview

The infrastructure is provisioned entirely using modular Terraform in region `eu-north-1`:

* **Networking (VPC Module):** Custom VPC with public and private subnets across multiple Availability Zones, managed route tables, and NAT Gateways.
* **Compute (ECS Fargate):** Serverless container execution for 3 core services:
  * `Vote`: Front-end voting web application (Python/Flask) behind an Application Load Balancer.
  * `Worker`: Background consumer processing votes from queue to storage (.NET Core).
  * `Result`: Real-time voting results dashboard (Node.js/Socket.io) exposed via ALB.
* **Databases & Caching:**
  * `ElastiCache (Redis)`: In-memory broker handling incoming votes.
  * `RDS (PostgreSQL)`: Relational database storing persistent vote records.
* **Security & Secrets:**
  * Dedicated ECS Execution and Task Roles supporting AWS Systems Manager (SSM) and ECS Exec.
  * Secrets Manager integration for secure, dynamic database credential injection.
  * Least-privilege Security Groups isolating tier-to-tier communication.

---

## 🚀 CI/CD Pipeline (GitHub Actions)

The deployment pipeline (`.github/workflows/deploy.yml`) implements trunk-based development with safety gates:

1. **Static Analysis & Linting:** Terraform format verification (`terraform fmt -check`) and validation (`terraform validate`).
2. **Container Build & Registry:** Multi-service container image build and push to Amazon ECR.
3. **Automated Dev Deployment:** Automated deployment to `dev` environment followed by automated HTTP smoke tests.
4. **Pull Request Workflow (Gatekeeper):** Dedicated workflow triggering non-destructive `terraform plan` execution across environments without applying changes.
5. **Production Deployment with Approval:** Gated deployment requiring manual environment review and approval before provisioning `prod` infrastructure and executing end-to-end verification.

---

## 🛠️ Verification & Teardown

* **End-to-End Testing:** Validated live voting flow across ALB endpoints (`Vote` on port 80 and `Result` on port 8080).
* **Cost Optimization & Clean Teardown:** Automated zero-downtime provisioning with confirmed complete teardown (`terraform destroy`) of all stateful (RDS, Redis) and compute (ALB, ECS) resources post-validation.
