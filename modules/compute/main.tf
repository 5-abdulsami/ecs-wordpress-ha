data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# --- EFS Storage (Moved here to avoid circular dependency) ---
resource "aws_efs_file_system" "monitoring_efs" {
  creation_token = "monitoring-state"
  encrypted      = true
  tags           = { Name = "monitoring-efs" }
}

resource "aws_efs_mount_target" "efs_mt" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.monitoring_efs.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [var.monitoring_sg_id] 
}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "main" {
  name = "wordpress-ha-cluster"
}

resource "aws_ecs_capacity_provider" "main" {
  name = "wordpress-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.main.arn
    managed_termination_protection = "DISABLED"
    managed_scaling {
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 80
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
  }
}

# --- Auto Scaling ---
resource "aws_launch_template" "main" {
  name_prefix   = var.launch_template_name
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_node_profile.name
  }

  # UPDATED: Only passing cluster_name and efs_id
  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {
    cluster_name = aws_ecs_cluster.main.name
    efs_id       = aws_efs_file_system.monitoring_efs.id
  }))

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ecs_sg_id]
  }
}

resource "aws_autoscaling_group" "main" {
  name                  = "wordpress-asg"
  vpc_zone_identifier   = var.private_subnet_ids
  min_size              = 2
  max_size              = 4
  desired_capacity      = 2
  protect_from_scale_in = true
  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

# --- Load Balancer ---
resource "aws_lb" "main" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "main" {
  name        = "wordpress-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path    = "/"
    matcher = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
