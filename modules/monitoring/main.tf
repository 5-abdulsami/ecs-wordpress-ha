


# ------------------------------------------------------------------------------
# 2. Alerting (SNS) - Purpose: Channel for Prometheus Alerts
# ------------------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name = "sre-central-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ------------------------------------------------------------------------------
# 3. Node Exporter (Daemon) - Purpose: Hardware metrics for EVERY node
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "node_exporter" {
  family                   = "node-exporter"
  network_mode             = "host"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.ecs_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "node-exporter"
      image     = "prom/node-exporter:latest"
      cpu       = 128
      memory    = 256
      essential = true
      command   = ["--path.procfs=/host/proc", "--path.sysfs=/host/sys", "--path.rootfs=/rootfs"]
      portMappings = [{ containerPort = 9100, hostPort = 9100, protocol = "tcp" }]
      mountPoints = [
        { sourceVolume = "proc", containerPath = "/host/proc", readOnly = true },
        { sourceVolume = "sys", containerPath = "/host/sys", readOnly = true },
        { sourceVolume = "root", containerPath = "/rootfs", readOnly = true }
      ]
    }
  ])

  volume {
  name      = "proc"
  host_path = "/proc"
}

volume {
  name      = "sys"
  host_path = "/sys"
}

volume {
  name      = "root"
  host_path = "/"
}
}

resource "aws_ecs_service" "node_exporter" {
  name                = "node-exporter"
  cluster             = var.ecs_cluster_id
  task_definition     = aws_ecs_task_definition.node_exporter.arn
  scheduling_strategy = "DAEMON"
}

# ------------------------------------------------------------------------------
# 4. Monitoring Plane (Prometheus/Grafana) - Purpose: Centralized Replica
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "monitoring" {
  family                   = "central-monitoring"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.prometheus_task_role_arn # Role with ecs:ListTasks

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = "prom/prometheus:latest"
      cpu       = 256
      memory    = 512
      essential = true
      mountPoints = [
        { sourceVolume = "efs-data", containerPath = "/etc/prometheus" },
        { sourceVolume = "efs-data", containerPath = "/prometheus" }
      ]
      portMappings = [{ containerPort = 9090, protocol = "tcp" }]
    },
    {
      name      = "grafana"
      image     = "grafana/grafana:latest"
      cpu       = 256
      memory    = 512
      essential = true
      mountPoints = [{ sourceVolume = "efs-data", containerPath = "/var/lib/grafana" }]
      portMappings = [{ containerPort = 3000, protocol = "tcp" }]
    }
  ])

  volume {
    name = "efs-data"
    efs_volume_configuration { file_system_id = var.monitoring_efs_id }
  }
}

resource "aws_ecs_service" "monitoring" {
  name            = "monitoring-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.monitoring.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.monitoring_sg_id]
  }
}
