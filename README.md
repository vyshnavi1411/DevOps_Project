# Cloud Infrastructure Automation & Monitoring Pipeline

This project implements an automated DevOps pipeline to provision AWS infrastructure and deploy monitoring tools using Infrastructure as Code and configuration management.

## Tech Stack

Jenkins | Terraform | AWS EC2 | Ansible | Prometheus | Grafana | Linux

## Project Overview

A Jenkins CI/CD pipeline provisions an EC2 instance on AWS using Terraform. After the infrastructure is created, Ansible automatically configures the server and installs Prometheus and Grafana for monitoring and visualization.

## Workflow

1. Jenkins pipeline is triggered.
2. Terraform provisions infrastructure on AWS.
3. EC2 instance details are retrieved from Terraform outputs.
4. A dynamic Ansible inventory is generated.
5. Ansible installs and configures Prometheus and Grafana.
6. Monitoring dashboards become available on the EC2 instance.

## Monitoring Services

Prometheus → `http://<EC2_PUBLIC_IP>:9090`
Grafana → `http://<EC2_PUBLIC_IP>:3000`

## Features

* Infrastructure as Code with Terraform
* CI/CD pipeline with Jenkins
* Automated server configuration using Ansible
* Monitoring setup with Prometheus and Grafana
* Dynamic inventory generation for EC2 instances

## Author

Vyshnavi Kusukuntla
