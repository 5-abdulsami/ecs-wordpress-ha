resource "aws_security_group" "rds_sg" {
  name   = "wordpress-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]
  }
}

resource "aws_db_subnet_group" "db_subnet" {
  name       = "wordpress-db-subnet"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "db" {
  identifier                  = "wordpress-ha-db"
  allocated_storage           = 20
  engine                      = var.db_engine
  engine_version              = "8.0"
  instance_class              = var.db_instance_class
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]
  multi_az                    = true
  skip_final_snapshot         = true
}

resource "aws_ssm_parameter" "db_host" {
  name  = "/wordpress/db_host"
  type  = "String"
  value = aws_db_instance.db.address
}

resource "aws_ssm_parameter" "db_user" {
  name  = "/wordpress/db_user"
  type  = "String"
  value = var.db_username
}
