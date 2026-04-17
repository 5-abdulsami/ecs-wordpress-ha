variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet CIDRs"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet CIDRs"
}

variable "allowed_admin_ip" {
  description = "The IP address allowed to access the admin interface"
  type        = string
}

variable "ecs_sg_id" {
  description = "Security Group ID for the ECS instances/tasks"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    Project = "wordpress-ha"
    Owner   = "SRE-Team"
  }
}