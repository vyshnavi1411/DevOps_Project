terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
backend "s3" {
  bucket         = "devops-automation-project-vysh"
  key            = "terraform.tfstate"
  region         = "us-east-1"
  use_lockfile = true
  encrypt        = true
} 
}
provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}

resource "random_id" "random" {
  byte_length = 2
}
  
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true


lifecycle {
  create_before_destroy = true
}
tags = {
  Name  = "main-vpc-project-${random_id.random.dec}"
}
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw-project-${random_id.random.dec}"
    
  }
  
  }
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block ="0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags={
    Name = "public-rt-project-${random_id.random.dec}"
  }
}
resource "aws_default_route_table" "private_rt" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  tags={
    Name = "private-rt-project-${random_id.random.dec}"
  } 
}
resource "aws_subnet" "public_subnet" {
  count                   = length(var.access_ip)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr,8,count.index) 
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}-project-${random_id.random.dec}"
  }
  
}

resource "aws_subnet" "private_subnet" {
  count             = length(var.access_ip)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr,8,count.index + length(var.access_ip)) 

  tags = {
    Name = "private-subnet-${random_id.random.dec}-${count.index + 1}"
  }
}
resource  "aws_route_table_association" "public_rt_assoc" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "project_sg" {
  name        = "project-sg-${random_id.random.dec}"
  description = "Security group for allowing all inbound and outbound traffic"
  vpc_id      = aws_vpc.main.id

}
resource "aws_security_group_rule" "allow_all_inbound" {
  type              = "ingress"
  from_port        = 0
  to_port          = 65535
  protocol         = "-1"
  cidr_blocks      = [var.access_ip]
  security_group_id = aws_security_group.project_sg.id
  description = "Allow all inbound traffic"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port        = 0
  to_port          = 65535
  protocol         = "-1"
  cidr_blocks      = [var.access_ip]
  security_group_id = aws_security_group.project_sg.id
  description = "Allow all outbound traffic"
}
resource "aws_security_group_rule" "allow_prometheus" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.project_sg.id
}
