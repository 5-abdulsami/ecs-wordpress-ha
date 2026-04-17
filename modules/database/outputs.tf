output "db_endpoint" {
  description = "The endpoint of the RDS instance (used for WordPress DB connection)"
  value       = aws_db_instance.db.endpoint
}

output "db_host_arn" {
  description = "The ARN of the RDS host parameter"
  value       = aws_ssm_parameter.db_host.arn
}

output "db_user_arn" {
  description = "The ARN of the RDS user parameter"
  value       = aws_ssm_parameter.db_user.arn
}

output "db_password_arn" {
  description = "The ARN of the RDS password parameter"
  value       = "${aws_db_instance.db.master_user_secret[0].secret_arn}:password::"
}

output "db_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.db.id
}
