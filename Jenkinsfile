pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '822127610519'
        ECR_REPOSITORY = 'trend-app'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPOSITORY}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t ${ECR_REPOSITORY}:latest .
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login \
                    --username AWS \
                    --password-stdin ${ECR_REGISTRY}
                '''
            }
        }

        stage('Tag Docker Image') {
            steps {
                sh '''
                    docker tag \
                    ${ECR_REPOSITORY}:latest \
                    ${IMAGE_NAME}:latest
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    docker push ${IMAGE_NAME}:latest
                '''
            }
        }
    }

    post {
        success {
            echo 'Trend application image successfully pushed to ECR.'
        }

        failure {
            echo 'Trend application pipeline failed.'
        }
    }
}
