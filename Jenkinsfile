pipeline {
    agent any

    environment {
        DOCKERHUB_REPOSITORY = 'yogabharath/guvi-trend-app'
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        AWS_REGION = 'ap-south-1'
        EKS_CLUSTER = 'trend-cluster'
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
                    env.IMAGE_NAME = "${env.DOCKERHUB_REPOSITORY}:${env.IMAGE_TAG}"

                    echo "Docker Image: ${env.IMAGE_NAME}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "===== BUILDING DOCKER IMAGE ====="

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

                    docker rm -f trend-ci-test 2>/dev/null || true

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

                    docker push ${IMAGE_NAME}
                '''
            }
        }

        stage('Configure EKS') {
            steps {
                sh '''
                    echo "===== CONFIGURING EKS ====="

                    mkdir -p /var/lib/jenkins/.kube

                    aws eks update-kubeconfig \
                      --region ${AWS_REGION} \
                      --name ${EKS_CLUSTER} \
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

                    echo "===== APPLYING SERVICE ====="

                    kubectl apply \
                      -f kubernetes-manifests/service.yaml \
                      --kubeconfig ${KUBECONFIG}

                    echo "===== APPLYING DEPLOYMENT ====="

                    kubectl apply \
                      -f kubernetes-manifests/deployment.yaml \
                      --kubeconfig ${KUBECONFIG}

                    echo "===== UPDATING DEPLOYMENT IMAGE ====="

                    kubectl set image \
                      deployment/trend-app \
                      trend-app=${IMAGE_NAME} \
                      --kubeconfig ${KUBECONFIG}

                    echo "===== IMAGE UPDATED ====="

                    kubectl get deployment trend-app \
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

                    echo "===== DEPLOYMENT STATUS ====="

                    kubectl get deployment trend-app \
                      -o wide \
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

        stage('Test EKS Application') {
            steps {
                sh '''
                    echo "===== GETTING LOAD BALANCER ====="

                    LB_HOST=$(kubectl get svc trend-service \
                      --kubeconfig ${KUBECONFIG} \
                      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

                    echo "Load Balancer: ${LB_HOST}"

                    if [ -z "$LB_HOST" ]; then
                        echo "ERROR: Load Balancer hostname not available"
                        exit 1
                    fi

                    echo "===== TESTING EKS APPLICATION ====="

                    for i in {1..30}; do

                        if curl -f \
                          --connect-timeout 5 \
                          --max-time 10 \
                          http://${LB_HOST}:3000 > /dev/null 2>&1; then

                            echo "===== EKS APPLICATION TEST PASSED ====="

                            echo "Application URL:"
                            echo "http://${LB_HOST}:3000"

                            exit 0
                        fi

                        echo "Attempt $i/30: Application not ready..."
                        sleep 10
                    done

                    echo "===== EKS APPLICATION TEST FAILED ====="
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            echo 'Trend CI/CD pipeline completed successfully.'
            echo "Docker Image: ${env.IMAGE_NAME}"
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
