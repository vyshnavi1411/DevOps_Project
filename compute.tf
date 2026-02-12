data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "random_id" "random_node_id" {
  byte_length = 2
  count       = var.main_instance_count
}

resource "aws_key_pair" "deployer_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "web_server" {
  count         = var.main_instance_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id              = aws_subnet.public_subnet[count.index].id
  vpc_security_group_ids = [aws_security_group.project_sg.id]
  key_name               = aws_key_pair.deployer_key.key_name

  # Upgrade Python for Ansible compatibility
  user_data = <<-EOF
#!/bin/bash
set -e

# Update packages
apt-get update -y

# Install Python 3.10
apt-get install -y python3.10 python3.10-distutils python3-pip

# Set Python 3.10 as default python3
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
update-alternatives --set python3 /usr/bin/python3.10

# Verify installation
python3 --version

# Mark cloud-init completion
echo "Python 3.10 setup complete"
EOF


  tags = {
    Name = "web-server-${random_id.random_node_id[count.index].dec}"
  }
}
