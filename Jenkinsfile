pipeline {
    agent any

    environment {
        DOCKERHUB_REPOSITORY = 'yogabharath/guvi-trend-app'
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
    }

    stages {

        stage('Set Image Tag') {
            steps {
                script {
                    IMAGE_TAG = "${BUILD_NUMBER}"
                    env.IMAGE_TAG = IMAGE_TAG

                    echo "Docker Image: ${DOCKERHUB_REPOSITORY}:${IMAGE_TAG}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "===== BUILDING DOCKER IMAGE ====="

                    docker build \
                      -t ${DOCKERHUB_REPOSITORY}:${IMAGE_TAG} \
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
                        echo "===== LOGIN TO DOCKERHUB ====="

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

                    docker push \
                      ${DOCKERHUB_REPOSITORY}:${IMAGE_TAG}
                '''
            }
        }

        stage('Configure EKS') {
            steps {
                sh '''
                    echo "===== CONFIGURING EKS ====="

                    aws eks update-kubeconfig \
                      --region ap-south-1 \
                      --name trend-cluster \
                      --kubeconfig ${KUBECONFIG}

                    echo "===== VERIFYING EKS ACCESS ====="

                    kubectl get nodes \
                      --kubeconfig ${KUBECONFIG}
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    echo "===== CHECKING KUBERNETES MANIFESTS ====="

                    ls -la kubernetes-manifests/

                    echo "===== APPLYING DEPLOYMENT ====="

                    kubectl apply \
                      -f kubernetes-manifests/deployment.yaml \
                      --kubeconfig ${KUBECONFIG}

                    echo "===== APPLYING SERVICE ====="

                    kubectl apply \
                      -f kubernetes-manifests/service.yaml \
                      --kubeconfig ${KUBECONFIG}
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "===== WAITING FOR DEPLOYMENT ====="

                    kubectl rollout status \
                      deployment/trend-app \
                      --kubeconfig ${KUBECONFIG} \
                      --timeout=180s

                    echo "===== PODS ====="

                    kubectl get pods \
                      -o wide \
                      --kubeconfig ${KUBECONFIG}

                    echo "===== DEPLOYMENT ====="

                    kubectl get deployment trend-app \
                      --kubeconfig ${KUBECONFIG}

                    echo "===== SERVICE ====="

                    kubectl get service trend-service \
                      --kubeconfig ${KUBECONFIG}

                    echo "===== APPLICATION LOAD BALANCER ====="

                    kubectl get service trend-service \
                      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' \
                      --kubeconfig ${KUBECONFIG}

                    echo ""
                '''
            }
        }
    }

    post {
        success {
            echo 'Trend CI/CD pipeline completed successfully.'
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
