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

        // Approval only for DEV
        stage('Validate Apply') {
            when { branch 'dev' }
            steps {
                input message: "Apply Terraform changes to DEV?", ok: "Apply"
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

                    // Dynamic inventory with Python 3.10
                    sh """
                    cat <<EOF > dynamic_inventory.ini
[web]
${INSTANCE_IP} ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3.10
EOF
                    """
                }
            }
        }

        stage('Wait for Instance Health') {
            steps {
                sh "aws ec2 wait instance-status-ok --instance-ids ${INSTANCE_ID} --region us-east-1"
            }
        }

        // Extra wait for SSH + cloud-init
        stage('Wait for SSH Ready') {
            steps {
                sh 'sleep 60'
            }
        }

        // Approval before Ansible (DEV only)
        stage('Validate Ansible') {
            when { branch 'dev' }
            steps {
                input message: "Run Ansible configuration?", ok: "Run"
            }
        }

        stage('Ansible Configuration') {
            steps {
                sh 'ansible-playbook install-monitoring.yml -i dynamic_inventory.ini'
            }
        }

        // Manual destroy confirmation for all branches
        stage('Validate Destroy') {
            steps {
                input message: "CRITICAL: Destroy infrastructure?", ok: "Destroy"
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
