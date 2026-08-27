pipeline {
    agent any

    environment {
        DOCKERHUB_REPOSITORY = 'yogabharath/guvi-trend-app'
        IMAGE_TAG = 'latest'
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
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
                    docker build \
                      -t ${DOCKERHUB_REPOSITORY}:${IMAGE_TAG} \
                      .
                '''
            }
        }

        stage('Test Docker Image') {
            steps {
                sh '''
                    docker run -d \
                      --name trend-ci-test \
                      -p 3000:3000 \
                      ${DOCKERHUB_REPOSITORY}:${IMAGE_TAG}

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
                    docker push ${DOCKERHUB_REPOSITORY}:${IMAGE_TAG}
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    kubectl apply \
                      -f kubernetes-manifests/deployment.yaml \
                      --kubeconfig ${KUBECONFIG}

                    kubectl apply \
                      -f kubernetes-manifests/service.yaml \
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
            echo 'Trend application successfully built, tested, pushed to DockerHub, and deployed to EKS.'
        }

        failure {
            echo 'Trend application pipeline failed.'
        }

        always {
            sh '''
                docker rm -f trend-ci-test 2>/dev/null || true
                docker logout || true
            '''
        }
    }
}
