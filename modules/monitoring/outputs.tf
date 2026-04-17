output "monitoring_efs_id" {
  description = "The ID of the EFS filesystem used for Prometheus/Grafana state"
  value       = var.monitoring_efs_id
}

output "sns_alerts_topic_arn" {
  description = "The ARN of the SNS topic for SRE alerts"
  value       = aws_sns_topic.alerts.arn
}
