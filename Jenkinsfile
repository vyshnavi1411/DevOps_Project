pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
        AWS_DEFAULT_REGION = 'us-east-1'
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
                sh 'terraform init -no-color'
                sh "cat ${BRANCH_NAME}.tfvars"
            }
        }

        stage('Terraform Plan') {
            steps {
                sh "terraform plan -var-file=${BRANCH_NAME}.tfvars"
            }
        }

        // --- CD Logic for Dev: Ask for permission before Apply ---
        stage('Validate Apply') {
            when { branch 'dev' } 
            steps {
                input message: "Do you want to apply this Terraform plan to DEV?", ok: "Apply"
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    sh "terraform apply -auto-approve -var-file=${BRANCH_NAME}.tfvars"

                    env.INSTANCE_IP = sh(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
                    env.INSTANCE_ID = sh(script: 'terraform output -raw instance_id', returnStdout: true).trim()

                    sh """
                    echo "[web]" > dynamic_inventory.ini
                    echo "${INSTANCE_IP}" >> dynamic_inventory.ini
                    """
                }
            }
        }

        stage('Wait for AWS Instance Health') {
            steps {
                sh "aws ec2 wait instance-status-ok --instance-ids ${INSTANCE_ID} --region us-east-1"
            }
        }

        // --- CD Logic for Dev: Ask for permission before Ansible ---
        stage('Validate Ansible') {
            when { branch 'dev' }
            steps {
                input message: "Do you want to run Ansible on DEV?", ok: "Run Ansible"
            }
        }

        stage('Ansible Configuration') {
            steps {
                sh 'ansible-playbook install-monitoring.yml -i dynamic_inventory.ini'
            }
        }

        // --- Permission for Destroy (Required for BOTH branches as per your request) ---
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
            sh 'rm -f dynamic_inventory.ini'
        }
        failure {
            // Note: Auto-destroy on failure might be risky for production (main)
            sh "terraform destroy -auto-approve -var-file=${BRANCH_NAME}.tfvars || echo 'Cleanup failed or not required.'"
        }
    aborted {
        sh "terraform destroy -auto-approve -var-file=${BRANCH_NAME}.tfvars || echo 'Cleanup failed or not required.'"
    }
}