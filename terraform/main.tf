terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Security group: open SSH, Jenkins (8080), app port (80)
resource "aws_security_group" "blinkit_sg" {
  name        = "blinkit-sg"
  description = "Allow SSH, Jenkins, and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  tags = { Name = "blinkit-sg" }
}

# EC2 instance
resource "aws_instance" "blinkit_server" {
  ami                    = var.ami_id
  instance_type          = "t2.medium"
  key_name               = "blinkit-key"
  vpc_security_group_ids = [aws_security_group.blinkit_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = { Name = "blinkit-jenkins-server" }
}