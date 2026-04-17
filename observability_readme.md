# 🌐 Highly Available WordPress with SRE Observability (Terraform)

## 1\. Architecture Explanation

This deployment features a multi-tier, highly available (HA) architecture with a dedicated **SRE Monitoring Layer**.

  * **Compute & Orchestration:** WordPress runs on **AWS ECS (EC2 Launch Type)** across two Availability Zones. An Application Load Balancer (ALB) distributes traffic and performs health checks.
  * **Database:** **Amazon RDS MySQL 8.0** in a Multi-AZ configuration for automatic failover.
  * **Observability Layer:** A custom Terraform module deploys CloudWatch Alarms, an SNS alerting topic, and a centralized Dashboard.
  * **Security:** IAM roles follow least-privilege; secrets are injected via **AWS SSM Parameter Store**.

## 2\. Service Level Objectives (SLOs) & Thresholds

To ensure reliability, the following SLOs were implemented via CloudWatch Alarms:

| SLO Type | Metric | Threshold | Logic |
| :--- | :--- | :--- | :--- |
| **Latency** | `TargetResponseTime` | **500ms** | p95 latency over 1 minute. |
| **Availability** | `HTTPCode_Target_5XX_Count` | **\> 5** | Sum of server errors over 5 minutes. |
| **Saturation** | `CPUUtilization` | **80%** | **Composite Alarm**: Fires if ECS *OR* RDS CPU exceeds 80%. |

## 3\. Deployment & Validation

### Step 1: Provision Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### Step 2: Verify Monitoring & SNS

1.  Check your email for the **AWS Notification - Subscription Confirmation**.
2.  Navigate to **CloudWatch \> Dashboards** to view the `WordPress-SLO-Dashboard`.

### Step 3: Synthetic Event Simulation (Stress Test)

Run the provided bash script to force an SLO breach and test the alerting pipeline:

```bash
chmod +x simulation_script.sh
./simulation_script.sh
```

*This script generates high-frequency requests and simulated 5XX errors to trigger the Latency and Error Rate alarms.*

## 4\. Troubleshooting & Known Limitations

  * **p95 Alarm Error:** CloudWatch Alarms require `extended_statistic = "p95"` instead of the standard `statistic` block.
  * **Data Latency:** CloudWatch metrics take 2–5 minutes to aggregate. If the dashboard shows "No Data," increase the duration of the stress test.
  * **Persistence:** Currently uses host-path mounts. For production, **Amazon EFS** is required for shared media storage across nodes.

## 5\. GenAI Usage Summary (Mandatory)

| Task | AI Tool | Prompt Used / Contribution |
| :--- | :--- | :--- |
| **SLO Proposal** | Gemini 3 Flash | "Suggest 3 SRE SLOs for a WordPress site on ECS/RDS within Free Tier." |
| **IaC Generation** | Gemini 3 Flash | "Generate Terraform for a CloudWatch Composite Alarm monitoring ECS and RDS CPU." |
| **Dashboard Design** | Gemini 3 Flash | "Create a CloudWatch Dashboard JSON for Latency (p95), 5XX Errors, and Saturation." |
| **Alarm Debugging** | Gemini 3 Flash | "Error: expected statistic to be one of Average/Sum, got p95." (Solution: `extended_statistic`) |
| **Load Simulation** | Gemini 3 Flash | "Write a Bash script to simulate high latency and 5XX errors on an ALB URL." |
