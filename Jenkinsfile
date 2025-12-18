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
            }
        }

        /* ================= DEV BRANCH (Continuous Delivery) ================= */

        stage('Approve Terraform Plan (DEV)') {
            when { branch 'dev' }
            input {
                message "DEV: Approve Terraform Plan?"
                ok "Approve Plan"
            }
            steps {
                echo "Plan approved for DEV"
            }
        }

        stage('Terraform Plan (DEV)') {
            when { branch 'dev' }
            steps {
                sh "terraform plan -var-file=dev.tfvars"
            }
        }

        stage('Approve Terraform Apply (DEV)') {
            when { branch 'dev' }
            input {
                message "DEV: Approve Terraform Apply?"
                ok "Apply"
            }
            steps {
                echo "Apply approved for DEV"
            }
        }

        stage('Terraform Apply (DEV)') {
            when { branch 'dev' }
            steps {
                sh "terraform apply -auto-approve -var-file=dev.tfvars"
            }
        }

        /* ================= MAIN BRANCH (Continuous Deployment) ================= */

        stage('Terraform Plan (MAIN)') {
            when { branch 'main' }
            steps {
                sh "terraform plan -var-file=main.tfvars"
            }
        }

        stage('Terraform Apply (MAIN)') {
            when { branch 'main' }
            steps {
                sh "terraform apply -auto-approve -var-file=main.tfvars"
            }
        }

        stage('Approve Destroy (MAIN)') {
            when { branch 'main' }
            input {
                message "MAIN: Approve Terraform Destroy?"
                ok "Destroy"
            }
            steps {
                echo "Destroy approved for MAIN"
            }
        }

        stage('Terraform Destroy (MAIN)') {
            when { branch 'main' }
            steps {
                sh "terraform destroy -auto-approve -var-file=main.tfvars"
            }
        }
    }
}
