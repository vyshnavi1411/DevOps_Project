pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
        AWS_DEFAULT_REGION = 'us-east-1'

        // Ensure Jenkins can find terraform, aws & ansible
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
                sh '''
                terraform init -no-color
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                sh '''
                terraform plan -no-color
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    sh '''
                    terraform apply -auto-approve -no-color
                    '''

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

        stage('Ansible Configuration') {
            steps {
                sh '''
                which ansible-playbook
                ansible-playbook --version

                ansible-playbook \
                playbooks/grafana.yml \
                -i dynamic_inventory.ini
                '''
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
            echo "❌ Pipeline failed. Check logs."
        }
    }
}
