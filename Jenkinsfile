pipeline{
    agent any
    environment{
        TF_IN_AUTOMATION = 'true'
        TF_CLI_CONFIG_FILE = credentials('Vyshh')
    }
    environment {
    PATH = "/usr/local/bin:/opt/homebrew/bin:${env.PATH}"
}
    stages {
        stage('Init') {
            steps {
               sh 'ls'
               sh 'terraform init -no-color'
            }
        }
        stage('Plan') {
            steps {
                sh 'terraform plan -no-color'
            }
        }
        
    }
}
