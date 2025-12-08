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
    count= var.main_instance_count

}
resource "aws_key_pair" "deployer_key" {
    key_name   = var.key_name
    public_key = file(var.public_key_path)

}
resource "aws_instance" "web_server" {
    count= var.main_instance_count
    ami=data.aws_ami.ubuntu.id
    instance_type=var.instance_type
    subnet_id=aws_subnet.public_subnet[count.index].id
    key_name=aws_key_pair.deployer_key.key_name
    vpc_security_group_ids=[aws_security_group.project_sg.id]
    # user_data = templatefile("main-userdata.tpl", {
    #     new_hostname = "web-server-${random_id.random_node_id[count.index].dec}"
    # })
    tags={
        Name="web-server-${random_id.random_node_id[count.index].dec}"   
    }
}
resource "null_resource" "write_ip" {
  depends_on = [aws_instance.web_server]

  triggers = {
    ip_list = join("\n", aws_instance.web_server.*.public_ip)
  }

  provisioner "local-exec" {
    command = <<EOT
echo "[grafana]" > aws_hosts
echo "${self.triggers.ip_list} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}" >> aws_hosts
EOT
  }
}
resource "null_resource" "grafana_provisioner" {
  depends_on = [aws_instance.web_server]

  provisioner "remote-exec" {
    connection{
        type        = "ssh"
        host        = aws_instance.web_server[0].public_ip
        user        = "ubuntu"
        private_key = file(var.private_key_path)
        timeout   = "5m"
    }
    inline =["echo 'Connection test successful instance is rechable via ssh'"]
  }
  
    provisioner "local-exec" {
  command = "ANSIBLE_CONFIG=/Users/vyshu/Desktop/MiniProject/ansible.cfg ansible all -i /Users/vyshu/Desktop/MiniProject/aws_hosts --private-key ${var.private_key_path} -m ping"
}
  }
resource "null_resource" "ansible_installer" {
  depends_on = [
    aws_instance.web_server,
    null_resource.write_ip
  ]

  provisioner "local-exec" {
    command = <<EOT
echo "Waiting for EC2 SSH to become fully ready..."
sleep 30

ANSIBLE_CONFIG=ansible.cfg \
ansible-playbook -i aws_hosts --private-key ${var.private_key_path} install-monitoring.yml
EOT
  }
}

 
 













