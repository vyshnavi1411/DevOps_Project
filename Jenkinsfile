pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_CLI_CONFIG_FILE = credentials('Vyshh')
        PATH = "/usr/local/bin:/opt/homebrew/bin:/Users/vyshu/Library/Python/3.12/bin:${PATH}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init -reconfigure -no-color'
                sh "cat ${BRANCH_NAME}.tfvars"
            }
        }

        stage('Terraform Plan') {
            steps {
                sh "terraform plan -var-file=${BRANCH_NAME}.tfvars"
            }
        }

        // Approval only for dev branch
        stage('Validate Apply') {
            when { branch 'dev' }
            steps {
                input message: "Do you want to apply Terraform changes to DEV?", ok: "Apply"
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    sh "terraform apply -auto-approve -var-file=${BRANCH_NAME}.tfvars"

                    env.INSTANCE_IP = sh(
                        script: 'terraform output -raw instance_public_ip',
                        returnStdout: true
                    ).trim()

                    env.INSTANCE_ID = sh(
                        script: 'terraform output -raw instance_id',
                        returnStdout: true
                    ).trim()

                    // Create dynamic inventory with Python 3.10
                    // Use auto_silent to let Ansible find the correct Python version automatically
sh """
cat <<EOF > dynamic_inventory.ini
[web]
${INSTANCE_IP} ansible_user=ubuntu ansible_python_interpreter=auto_silent
EOF
"""
                }
            }
        }

        stage('Wait for AWS Instance Health') {
            steps {
                sh "aws ec2 wait instance-status-ok --instance-ids ${INSTANCE_ID} --region us-east-1"
            }
        }

        // Important: wait for cloud-init + Python installation
        stage('Wait for Instance Setup') {
            steps {
                echo "Waiting for instance initialization..."
                sh 'sleep 60'
            }
        }

        // Approval before Ansible (dev only)
        stage('Validate Ansible') {
            when { branch 'dev' }
            steps {
                input message: "Do you want to run Ansible?", ok: "Run Ansible"
            }
        }

        stage('Ansible Configuration') {
            steps {
                sh 'ansible-playbook install-monitoring.yml -i dynamic_inventory.ini'
            }
        }

        // Manual destroy confirmation
        stage('Validate Destroy') {
            steps {
                input message: "CRITICAL: Do you want to destroy the infrastructure?", ok: "Destroy"
            }
        }

        stage('Terraform Destroy') {
            steps {
                sh "terraform destroy -auto-approve -var-file=${BRANCH_NAME}.tfvars"
            }
        }
    }

    post {
        always {
            sh 'rm -f dynamic_inventory.ini || true'
        }

        failure {
            echo "Pipeline failed. Cleaning up resources..."
            sh "terraform destroy -auto-approve -var-file=${BRANCH_NAME}.tfvars || true"
        }

        aborted {
            echo "Pipeline aborted. Cleaning up resources..."
            sh "terraform destroy -auto-approve -var-file=${BRANCH_NAME}.tfvars || true"
        }
    }
}
