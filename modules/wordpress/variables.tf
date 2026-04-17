variable "cluster_id" {
  description = "ECS Cluster ID where the service will be deployed"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the IAM role that ECS tasks will use for execution"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security Group ID for the ECS instances/tasks"
  type        = string
}

variable "db_host_arn" {
  description = "SSM ARN for Database Host"
  type        = string
}

variable "db_user_arn" {
  description = "SSM ARN for Database User"
  type        = string
}

variable "db_password_arn" {
  description = "SSM ARN for Database Password"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "container_cpu" {
  type    = string
  default = "512"
}

variable "container_memory" {
  type    = string
  default = "512"
}

