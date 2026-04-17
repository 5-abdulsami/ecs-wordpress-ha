variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EC2 instances"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security Group ID for the ECS instances/tasks"
  type        = string
}

variable "alb_sg_id" {
  description = "Security Group ID for the Load Balancer"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for ECS nodes"
  type        = string
  default     = "t3.micro"
}

variable "launch_template_name" {
  description = "Name prefix for the launch template"
  type        = string
  default     = "wordpress-ecs-template"
}

variable "monitoring_sg_id" {
  description = "Security Group ID for monitoring tasks (allows 3000, 9090, 2049)"
  type        = string
}
