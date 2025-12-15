data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
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
    apt update -y
    apt install -y python3.10 python3.10-distutils
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
  EOF

  tags = {
    Name = "web-server-${random_id.random_node_id[count.index].dec}"
  }
}
