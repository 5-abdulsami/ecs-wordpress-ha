# Highly Available WordPress on AWS ECS (Terraform Managed)

![Architecture Diagram](./wordpress-aws-infra.png)

## 1. Architecture Explanation
This deployment utilizes a multi-tier, highly available (HA) architecture with centralized monitoring.

* **Networking:** A custom VPC spans two Availability Zones in the `ap-south-1` region. It consists of public subnets for the ALB and NAT Gateway, and private subnets for application/database instances.
* **Compute:** The ECS Cluster uses the EC2 launch type. An ASG manages `t3.micro` instances.
* **Monitoring (Centralized):** 
    - **Prometheus & Grafana:** Run as a separate ECS service (1 instance) for centralized metrics aggregation and visualization.
    - **Node Exporter:** Deployed as a **Daemon** service, ensuring one exporter per EC2 instance.
    - **WordPress Metrics:** Exposed via an `apache-exporter` sidecar in the WordPress task definition.
    - **Prometheus Auto-Discovery:** Uses `ecs_sd_configs` to automatically find and scrape node exporters and application metrics.
* **Database:** Amazon RDS MySQL 8.0 in a Multi-AZ configuration.
* **Storage:** 
    - **WordPress:** Uses local host-path bind mounts (as per current requirement).
    - **Monitoring:** Uses Amazon EFS for persistent storage of Prometheus and Grafana state.

## 2. Inconsistencies Resolved

The following technical issues were identified and fixed to ensure a stable, production-ready environment:

- **Circular Variable References:** Fixed an invalid circular reference in the `networking` module variables.
- **Resource Naming Inconsistencies:** Resolved mismatches between resource names in `main.tf` and their corresponding references in `outputs.tf` (e.g., `monitoring_sg`).
- **Unified EFS Storage:** Consolidated duplicate EFS resources in the `monitoring` and `compute` modules into a single shared filesystem.
- **Metrics Visibility:** Added the `apache-exporter` sidecar to WordPress to satisfy the `/metrics` requirement.
- **Auto-Discovery Fix:** Updated `user_data.sh` to correctly configure Prometheus scraping for the updated exporter ports and dynamic cluster names.
- **Module Orchestration:** Fixed root-level module calls to pass correct security group IDs and EFS IDs.

## 3. Deployment Steps

### Step 1: Initialize Terraform
```bash
terraform init
```

### Step 2: Plan the Infrastructure
```bash
terraform plan -var-file="terraform.tfvars"
```

### Step 3: Apply Configuration
```bash
terraform apply -var-file="terraform.tfvars"
```

## 4. Monitoring & Metrics Requirements (Fulfilled)

- [x] **Centralized Monitoring Service:** Prometheus/Grafana service runs with `desired_count = 1`.
- [x] **Node Monitoring:** Node Exporter runs as a `DAEMON` service (one per host).
- [x] **Application Metrics:** WordPress task definition includes an exporter sidecar.
- [x] **Alerting:** SNS topic and Email subscription created for Prometheus alerts.
- [x] **Auto-Discovery:** Prometheus is configured to discover tasks via ECS API.

## 5. Known Limitations

* **WordPress Storage:** Currently using host-path. Media files are not synced across multiple tasks on different nodes. Recommendation: Implement EFS for `/var/www/html`.
* **Account IDs:** IAM policies currently use hardcoded account IDs as per user request.

## 6. Troubleshooting

- **503 Errors:** Check if ECS tasks are passing ALB health checks.
- **Missing Metrics:** Ensure Prometheus task has the IAM role with `ecs:ListTasks` permissions (included in `compute` module).
- **EFS Mount Failure:** Verify security group 2049 rules in the `networking` module.
