#!/bin/bash
# 1. Join ECS Cluster
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config

# 2. WordPress Directory Setup
mkdir -p /var/www/wordpress_data
chown -R 33:33 /var/www/wordpress_data
chmod 755 /var/www/wordpress_data

# 3. Update and install EFS utilities
yum update -y
yum install -y amazon-efs-utils

# 4. Mount EFS (Terraform will pass the EFS ID as a variable)
mkdir -p /mnt/efs
mount -t efs -o tls ${efs_id}:/ /mnt/efs

# 5. Setup Directories for ECS Tasks
mkdir -p /mnt/efs/prometheus/data
mkdir -p /mnt/efs/grafana
chown -R 65534:65534 /mnt/efs/prometheus # Prometheus user
chown -R 472:472 /mnt/efs/grafana        # Grafana user

# 6. Write Prometheus Config (Using ecs_sd_configs for auto-discovery!)
cat << 'EOF' > /mnt/efs/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node-exporter'
    ecs_sd_configs:
      - region: ap-south-1
        cluster: ${cluster_name}
    relabel_configs:
      # Only scrape tasks running on port 9100 (Node Exporter)
      - source_labels: [__meta_ecs_task_container_port]
        action: keep
        regex: 9100

  - job_name: 'wordpress-app'
    ecs_sd_configs:
      - region: ap-south-1
        cluster: ${cluster_name}
    relabel_configs:
      # Scrape the Apache exporter port
      - source_labels: [__meta_ecs_task_container_port]
        action: keep
        regex: 9117
EOF

# 7. Start ECS Agent
systemctl enable --now ecs
