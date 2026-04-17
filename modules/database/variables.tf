variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the RDS instance"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security Group ID for the ECS instances/tasks"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_engine" {
  description = "Database engine (e.g., mysql, postgres)"
  type        = string
  default     = "mysql"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "wordpressdb"
}
