variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "alert_email" {
  description = "Email address for receiving CloudWatch SNS alerts"
  type        = string
}

variable "allowed_admin_ip" {
  description = "The IP address allowed to access the admin interface"
  type        = string
}
