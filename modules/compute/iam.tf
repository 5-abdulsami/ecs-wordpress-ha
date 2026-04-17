# --- Data Resources ---
data "aws_iam_policy" "ecs_ec2_role_policy" { name = "AmazonEC2ContainerServiceforEC2Role" }
data "aws_iam_policy" "ecs_task_execution_role_policy" { name = "AmazonECSTaskExecutionRolePolicy" }
data "aws_iam_policy" "ssm_core_policy" { name = "AmazonSSMManagedInstanceCore" }

# --- 1. EC2 Node Infrastructure Role (The Host) ---
resource "aws_iam_role" "ecs_node_role" {
  name = "wordpress-ecs-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = data.aws_iam_policy.ecs_ec2_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_node_ssm_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = data.aws_iam_policy.ssm_core_policy.arn
}

resource "aws_iam_instance_profile" "ecs_node_profile" {
  name = "wordpress-ecs-node-profile"
  role = aws_iam_role.ecs_node_role.name
}

# --- 2. ECS Task Execution Role (Pulling Images/Secrets) ---
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "wordpress-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_role_policy.arn
}

resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = "wordpress-ecs-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ssm:GetParameters", "secretsmanager:GetSecretValue", "kms:Decrypt"]
      Resource = ["arn:aws:ssm:ap-south-1:959157916756:parameter/wordpress/*", "arn:aws:secretsmanager:ap-south-1:959157916756:secret:rds!db-*"]
    }]
  })
}

# --- 3. ECS Task Role (Prometheus Service Discovery) ---
# Purpose: Allows Prometheus container to find other tasks in the cluster
resource "aws_iam_role" "prometheus_task_role" {
  name = "wordpress-prometheus-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "prometheus_discovery" {
  name = "PrometheusECSDiscovery"
  role = aws_iam_role.prometheus_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ecs:ListTasks", "ecs:DescribeTasks", "ecs:ListClusters", "ecs:DescribeContainerInstances", "ec2:DescribeInstances"]
      Resource = "*"
    }]
  })
}
