output "cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_task_execution_role_arn" {
  description = "The ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "prometheus_task_role_arn" { 
  value = aws_iam_role.prometheus_task_role.arn 
  description = "The ARN of the IAM Task Role with ecs:ListTasks permissions for Prometheus auto-discovery"
}

output "monitoring_efs_id" { 
  value = aws_efs_file_system.monitoring_efs.id
  description = "The ID of the EFS filesystem used for Prometheus/Grafana state"
}
output "target_group_arn" {
  description = "The ARN of the Load Balancer Target Group"
  value       = aws_lb_target_group.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Load Balancer"
  value       = aws_lb.main.dns_name
}
