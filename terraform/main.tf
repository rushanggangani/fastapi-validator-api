# 1. Provider Setup (Mumbai Region)
provider "aws" {
  region = "ap-south-1"
  profile = "personal-aws"
}

# 2. Automatically Fetch Latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 3. Security Group (Firewall Rules for SSH & Port 8000)
resource "aws_security_group" "api_sg" {
  name        = "fastapi-docker-sg"
  description = "Allow SSH and API traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

# 4. SSH Key Pair (Reads key file directly from your local Mac)
resource "aws_key_pair" "deployer_key" {
  key_name   = "fastapi-deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# 5. EC2 Instance Provisioning
resource "aws_instance" "api_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer_key.key_name
  vpc_security_group_ids = [aws_security_group.api_sg.id]

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  # Startup script to install Docker on initial boot
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "FastAPI-Docker-Server"
  }
}

resource "aws_eip" "api_eip" {
  instance = aws_instance.api_server.id
  domain   = "vpc"
}

# 6 Update the output to show the new Elastic IP instead
output "ec2_elastic_ip" {
  description = "Static Elastic IP address of the EC2 instance"
  value       = aws_eip.api_eip.public_ip
}