resource "aws_cloudwatch_log_group" "wp_logs" {
  name              = "/ecs/wordpress"
  retention_in_days = 30
}

# Task definition references the execution role for ECR/CloudWatch access and injects RDS creds via env vars
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "wordpress-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = var.execution_role_arn

  volume {
    name      = "wordpress-storage"
    host_path = "/var/www/wordpress_data"
  }

  container_definitions = jsonencode([    {
      name      = "wordpress"
      image     = "wordpress:latest"
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]
      secrets = [
        { name = "WORDPRESS_DB_HOST", valueFrom = var.db_host_arn },
        { name = "WORDPRESS_DB_USER", valueFrom = var.db_user_arn },
        { name = "WORDPRESS_DB_PASSWORD", valueFrom = var.db_password_arn },
      ]
      environment = [
        { name = "WORDPRESS_DB_NAME", value = var.db_name }
      ]
      mountPoints = [{
        sourceVolume  = "wordpress-storage"
        containerPath = "/var/www/html"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.wp_logs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name      = "apache-exporter"
      image     = "bitnami/apache-exporter:latest"
      essential = false
      portMappings = [{
        containerPort = 9117
        hostPort      = 9117
        protocol      = "tcp"
      }]
      command = ["--scrape_uri=http://localhost/server-status/?auto"]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.wp_logs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "exporter"
        }
      }
    }
])
}

# Runs 2 tasks across private subnets, registered to the ALB target group for traffic distribution
resource "aws_ecs_service" "wordpress" {
  name            = "wordpress-service"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 2
  launch_type     = "EC2"
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_sg_id]
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "wordpress"
    container_port   = 80
  }
}
