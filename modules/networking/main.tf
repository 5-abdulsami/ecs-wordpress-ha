data "aws_availability_zones" "available" {}

# Spreads across 2 AZs with per-AZ NAT gateways for HA egress from private subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "wordpress-prod-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name   = "wordpress-alb-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS instances only accept traffic from the ALB, not directly from the internet
resource "aws_security_group" "ecs_sg" {
  name   = "wordpress-ecs-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "monitoring" {
  name_prefix = "monitoring-sg"
  vpc_id      = module.vpc.vpc_id

  # 1. Allow Admin access (SSM/Direct)
  ingress {
    from_port   = 3000
    to_port     = 9090 # Range covering both 3000 and 9090
    protocol    = "tcp"
    cidr_blocks = [var.allowed_admin_ip]
  }

  # 3. Allow Monitoring Tasks to talk to EFS
  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Standalone rules to break circular dependency ---

# Allows ECS Nodes (in ecs_sg) to reach EFS (in monitoring_sg)
resource "aws_security_group_rule" "allow_nfsv4_from_ecs" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.monitoring.id
  source_security_group_id = aws_security_group.ecs_sg.id
}

# Allows Prometheus (in monitoring_sg) to scrape metrics from ECS Tasks (in ecs_sg)
resource "aws_security_group_rule" "allow_scraping_from_monitoring" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9117
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_sg.id
  source_security_group_id = aws_security_group.monitoring.id
}

