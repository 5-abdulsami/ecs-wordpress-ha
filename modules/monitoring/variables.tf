# --- Identity & Security ---
variable "alert_email" {
  description = "Email address to receive Prometheus/SRE alerts"
  type        = string
}

variable "monitoring_sg_id" {
  description = "Security Group ID for monitoring tasks (allows 3000, 9090, 2049)"
  type        = string
}

variable "monitoring_efs_id" {
  description = "The ID of the EFS filesystem used for Prometheus/Grafana state"
  type        = string
}

variable "ecs_cluster_id" {
  description = "The ARN/ID of the ECS cluster"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "The ARN of the ECS task execution role (for pulling images)"
  type        = string
}

variable "prometheus_task_role_arn" {
  description = "The ARN of the IAM Task Role with ecs:ListTasks permissions for auto-discovery"
  type        = string
}

# --- Network & Storage ---
variable "private_subnet_ids" {
  description = "List of private subnet IDs for EFS mount targets and monitoring tasks"
  type        = list(string)
}

# --- Metadata ---
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    Project = "wordpress-ha"
    Owner   = "SRE-Team"
  }
}
