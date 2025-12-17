pipeline {
    agent any
    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
        AWS_DEFAULT_REGION = 'us-east-1'
        PATH = "/usr/local/bin:/opt/homebrew/bin:/Users/vyshu/Library/Python/3.12/bin:${env.PATH}"
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
                sh 'cat $BRANCH_NAME.tfvars'
            }
        }
        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -var-file=$BRANCH_NAME.tfvars'
            }
        }

        /* ====== FROM 1st CODE (APPLY VALIDATION) ====== */
        stage('Validate Apply') {
            input {
                message "Do you want to apply this Terraform plan?"
                ok "Apply"
            }
            steps {
                echo 'Terraform Apply Approved'
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    sh 'terraform apply -auto-approve -var-file=$BRANCH_NAME.tfvars'

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

                    sh '''
                    echo "[web]" > dynamic_inventory.ini
                    echo "${INSTANCE_IP}" >> dynamic_inventory.ini
                    '''
                }
            }
        }

        stage('Wait for AWS Instance Health') {
            steps {
                echo "Waiting for instance ${env.INSTANCE_ID} to pass AWS health checks..."
                sh '''
                aws ec2 wait instance-status-ok \
                --instance-ids ${INSTANCE_ID} \
                --region us-east-1
                '''
                echo "Instance is healthy. Proceeding to Ansible."
            }
        }

        /* ====== FROM 1st CODE (ANSIBLE VALIDATION) ====== */
        stage('Validate Ansible') {
            input {
                message "Do you want to run Ansible?"
                ok "Run Ansible"
            }
            steps {
                echo 'Ansible Approved'
            }
        }

        stage('Ansible Configuration') {
            steps {
                sh '''
                which ansible-playbook
                ansible-playbook --version

                ansible-playbook install-monitoring.yml -i dynamic_inventory.ini
                '''
            }
        }

        /* ====== FROM 1st CODE (DESTROY VALIDATION) ====== */
        stage('Validate Destroy') {
            input {
                message "Do you want to destroy the infrastructure?"
                ok "Destroy"
            }
            steps {
                echo 'Destroy Approved'
            }
        }

        stage('Terraform Destroy') {
            steps {
                sh 'terraform destroy -auto-approve -var-file=$BRANCH_NAME.tfvars'
            }
        }
    }

    post {
        always {
            sh 'rm -f dynamic_inventory.ini'
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            sh 'terraform destroy -auto-approve -var-file=$BRANCH_NAME.tfvars || echo "Cleanup failed or was not necessary."'
        }
    }
}
