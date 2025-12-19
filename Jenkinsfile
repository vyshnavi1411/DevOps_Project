pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        SSH_CREDENTIALS_ID = 'was-deployer-ssh-key'
        ANSIBLE_HOST_KEY_CHECKING = 'False' 
        PATH = "/usr/local/bin:/opt/homebrew/bin:/Users/vyshu/Library/Python/3.12/bin:${PATH}"
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform init -no-color'
                sh "terraform plan -var-file=${BRANCH_NAME}.tfvars"
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    sh "terraform apply -auto-approve -var-file=${BRANCH_NAME}.tfvars"
                    
                    // Capture IP and ID
                    def ip = sh(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
                    env.INSTANCE_ID = sh(script: 'terraform output -raw instance_id', returnStdout: true).trim()

                    // Build inventory: adds ec2-user automatically
                    sh "echo '[web]\n${ip} ansible_user=ec2-user' > dynamic_inventory.ini"
                }
            }
        }

        stage('Wait for AWS') {
            steps {
                sh "aws ec2 wait instance-status-ok --instance-ids ${env.INSTANCE_ID}"
            }
        }

        stage('Run Ansible') {
            steps {
                ansiblePlaybook(
                    playbook: 'install-monitoring.yml',
                    inventory: 'dynamic_inventory.ini',
                    credentialsId: SSH_CREDENTIALS_ID
                )
                ansiblePlaybook(
                    playbook: 'test-grafana.yml',
                    inventory: 'dynamic_inventory.ini',
                    credentialsId: SSH_CREDENTIALS_ID
                )
            }
        }

        stage('Terraform Destroy') {
            steps {
                input message: "Destroy infrastructure?"
                sh "terraform destroy -auto-approve -var-file=${BRANCH_NAME}.tfvars"
            }
        }
    }

    post {
        always {
            sh 'rm -f dynamic_inventory.ini'
        }
    }
}