# ─────────────────────────────────────────────
#  terraform/main.tf
#  Provisions: k8s-control-plane + k8s-worker-1
#  Provider: AWS (adjust for your cloud)
# ─────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ── Provider ──────────────────────────────────────────────────────
provider "aws" {
  region = var.aws_region
}

# ── Variables ─────────────────────────────────────────────────────
variable "aws_region" {
  description = "AWS region to deploy into"
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI (update per region)"
  default     = "ami-0c7217cdde317cfec"   # us-east-1 Ubuntu 22.04
}

variable "instance_type" {
  description = "EC2 instance type for K8s nodes (min t3.medium for K8s)"
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  default     = "devops-key"
}

variable "vpc_id" {
  description = "VPC ID where instances will be launched"
  default     = ""   # leave empty to use default VPC
}

# ── Data Sources ──────────────────────────────────────────────────
data "aws_vpc" "selected" {
  default = var.vpc_id == "" ? true : false

  dynamic "filter" {
    for_each = var.vpc_id != "" ? [var.vpc_id] : []
    content {
      name   = "vpc-id"
      values = [filter.value]
    }
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# ── Security Group ────────────────────────────────────────────────
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-cluster-sg"
  description = "Security group for Kubernetes cluster nodes"
  vpc_id      = data.aws_vpc.selected.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  # Kubernetes API server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes API Server"
  }

  # etcd
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    self        = true
    description = "etcd"
  }

  # Kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10260
    protocol    = "tcp"
    self        = true
    description = "Kubelet API"
  }

  # NodePort services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NodePort Services"
  }

  # Flannel VXLAN
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    self        = true
    description = "Flannel VXLAN"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "k8s-cluster-sg"
    Project = "devops-prt"
  }
}

# ── k8s-control-plane Instance ────────────────────────────────────
resource "aws_instance" "k8s_control_plane" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = data.aws_subnets.public.ids[0]
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "k8s-control-plane"
    Role    = "kubernetes-master"
    Project = "devops-prt"
  }
}

# ── k8s-worker-1 Instance ─────────────────────────────────────────
resource "aws_instance" "k8s_worker_1" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = data.aws_subnets.public.ids[0]
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "k8s-worker-1"
    Role    = "kubernetes-worker"
    Project = "devops-prt"
  }
}

# ── Outputs ───────────────────────────────────────────────────────
output "k8s_control_plane_public_ip" {
  description = "Public IP of Kubernetes control plane"
  value       = aws_instance.k8s_control_plane.public_ip
}

output "k8s_control_plane_private_ip" {
  description = "Private IP of Kubernetes control plane"
  value       = aws_instance.k8s_control_plane.private_ip
}

output "k8s_worker_1_public_ip" {
  description = "Public IP of Kubernetes worker node"
  value       = aws_instance.k8s_worker_1.public_ip
}

output "k8s_worker_1_private_ip" {
  description = "Private IP of Kubernetes worker node"
  value       = aws_instance.k8s_worker_1.private_ip
}

output "ssh_control_plane" {
  description = "SSH command for control plane"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.k8s_control_plane.public_ip}"
}

output "ssh_worker_1" {
  description = "SSH command for worker node"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.k8s_worker_1.public_ip}"
}
