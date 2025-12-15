pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
        TF_CLI_CONFIG_FILE = credentials('Vyshh')
        SSH_CRED_ID = 'aws-deployer-ssh-key'
        PATH = "/usr/local/bin:/opt/homebrew/bin:${env.PATH}"
    }

    stages {

        stage('Terraform Init') {
            steps {
                sh 'ls'
                sh 'terraform init -no-color'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -no-color'
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    sh 'terraform apply -auto-approve -no-color'

                    env.INSTANCE_IP = sh(
                        script: 'terraform output -raw instance_public_ip',
                        returnStdout: true
                    ).trim()

                    env.INSTANCE_ID = sh(
                        script: 'terraform output -raw instance_id',
                        returnStdout: true
                    ).trim()

                    echo "Provisioned Instance IP: ${env.INSTANCE_IP}"
                    echo "Provisioned Instance ID: ${env.INSTANCE_ID}"

                    sh "echo '${env.INSTANCE_IP}' > dynamic_inventory.ini"
                }
            }
        }

        stage('Wait for AWS Instance Health') {
            steps {
                echo "Waiting for instance ${env.INSTANCE_ID} to pass AWS health checks..."
                sh "aws ec2 wait instance-status-ok --instance-ids ${env.INSTANCE_ID} --region us-east-1"
                echo "Instance is healthy. Proceeding to Ansible."
            }
        }

        stage('Ansible Configuration') {
            steps {
                ansiblePlaybook(
                    playbook: 'playbooks/grafana.yml',
                    inventory: 'dynamic_inventory.ini',
                    credentialsId: SSH_CRED_ID
                )
            }
        }
    }

    post {
        always {
            sh 'rm -f dynamic_inventory.ini'
        }
    }
}
