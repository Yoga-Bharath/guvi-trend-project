pipeline {
    agent any

    environment {
        DOCKERHUB_REPOSITORY = 'yogabharath/guvi-trend-app'

        AWS_REGION = 'ap-south-1'
        EKS_CLUSTER = 'trend-cluster'

        KUBECONFIG = '/var/lib/jenkins/.kube/config'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Set Image Tag') {
            steps {
                script {
                    env.IMAGE_TAG = "${BUILD_NUMBER}"
                    env.IMAGE_NAME = "${DOCKERHUB_REPOSITORY}:${IMAGE_TAG}"

                    echo "Docker Image: ${IMAGE_NAME}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                      -t ${IMAGE_NAME} \
                      .
                '''
            }
        }

        stage('Test Docker Image') {
            steps {
                sh '''
                    echo "===== STARTING TEST CONTAINER ====="

                    docker run -d \
                      --name trend-ci-test \
                      -p 3000:3000 \
                      ${IMAGE_NAME}

                    sleep 5

                    echo "===== TESTING APPLICATION ====="

                    curl -f http://localhost:3000

                    echo ""
                    echo "===== APPLICATION TEST PASSED ====="

                    docker stop trend-ci-test
                    docker rm trend-ci-test
                '''
            }
        }

        stage('Login to DockerHub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-trend',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        echo "${DOCKERHUB_TOKEN}" | \
                        docker login \
                        --username "${DOCKERHUB_USERNAME}" \
                        --password-stdin
                    '''
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                sh '''
                    echo "===== PUSHING IMAGE TO DOCKERHUB ====="

                    docker push ${IMAGE_NAME}
                '''
            }
        }

        stage('Configure EKS') {
            steps {
                sh '''
                    echo "===== CONFIGURING EKS ====="

                    aws eks update-kubeconfig \
                      --region ${AWS_REGION} \
                      --name ${EKS_CLUSTER} \
                      --kubeconfig ${KUBECONFIG}
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    echo "===== APPLYING KUBERNETES MANIFESTS ====="

                    kubectl apply \
                      -f kubernetes-manifests/service.yaml \
                      --kubeconfig ${KUBECONFIG}

                    echo "===== DEPLOYING IMAGE ${IMAGE_NAME} ====="

                    kubectl set image deployment/trend-app \
                      trend-app=${IMAGE_NAME} \
                      --kubeconfig ${KUBECONFIG}
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "===== ROLLOUT STATUS ====="

                    kubectl rollout status \
                      deployment/trend-app \
                      --kubeconfig ${KUBECONFIG} \
                      --timeout=180s

                    echo "===== DEPLOYMENT ====="

                    kubectl get deployment trend-app \
                      --kubeconfig ${KUBECONFIG}

                    echo "===== PODS ====="

                    kubectl get pods \
                      -o wide \
                      --kubeconfig ${KUBECONFIG}

                    echo "===== SERVICE ====="

                    kubectl get service trend-service \
                      --kubeconfig ${KUBECONFIG}
                '''
            }
        }
    }

    post {

        success {
            echo """
            ==========================================
            TREND APPLICATION DEPLOYMENT SUCCESSFUL
            ==========================================
            Docker Image: ${IMAGE_NAME}
            EKS Cluster: ${EKS_CLUSTER}
            Region: ${AWS_REGION}
            ==========================================
            """
        }

        failure {
            echo 'Trend CI/CD pipeline failed.'
        }

        always {
            sh '''
                docker rm -f trend-ci-test 2>/dev/null || true
                docker logout || true
            '''
        }
    }
}
