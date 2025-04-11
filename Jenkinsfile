pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "192.168.1.10:8082"
        IMAGE_NAME = "my-flask-app"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'docker-nexus-artifactory-repo-creds'
        HELM_CHART_DIR = "/var/jenkins_home/workspace/myApp/my-flask-app"
        HELM_RELEASE_NAME = "flask-app-release"
        HELM_NAMESPACE = "default"
    }

    stages {

        stage('Check and Install Helm') {
            steps {
                script {
                    def helmExists = sh(script: "which helm || true", returnStdout: true).trim()
                    if (!helmExists) {
                        echo "Helm not found. Installing..."
                        sh '''
                            curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                        '''
                    } else {
                        echo "Helm is already installed: ${helmExists}"
                    }
                }
            }
        }

        stage('Clean Jenkins Workspace') {
            steps {
                script {
                    echo "Cleaning Jenkins workspace before cloning..."
                    cleanWs()
                }
            }
        }

        stage('Clone Repository') {
            steps {
                git url: 'https://github.com/sgobi/pythonflasktestproject.git', branch: 'main'
            }
        }

        stage('Stop and Remove Old Container and Image') {
            steps {
                script {
                    def containerName = "flask-app"
                    sh "docker ps -q -f name=${containerName} | xargs --no-run-if-empty docker stop"
                    sh "docker ps -a -q -f name=${containerName} | xargs --no-run-if-empty docker rm"
                    def oldImage = sh(script: "docker images -q ${IMAGE_NAME}", returnStdout: true).trim()
                    if (oldImage) {
                        sh "docker rmi -f ${oldImage}"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Login to Artifactory Docker Registry') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: env.DOCKER_CREDENTIALS_ID,
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin http://${DOCKER_REGISTRY}
                        """
                    }
                }
            }
        }

        stage('Tag and Push Docker Image to Artifactory') {
            steps {
                script {
                    def fullImageName = "${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${fullImageName}"
                    sh "docker push ${fullImageName}"
                }
            }
        }

        stage('Update tag in values.yaml and Deploy with Helm') {
            steps {
                script {
                    echo "Helm chart directory: ${env.HELM_CHART_DIR}"
                    def valuesPath = "${env.HELM_CHART_DIR}/values.yaml"
                    echo "Updating tag in: ${valuesPath}"

                    sh """
                        sed -i 's|repository:.*|repository: "${DOCKER_REGISTRY}/${IMAGE_NAME}"|' ${valuesPath}
                        sed -i 's|tag: *""|tag: "${IMAGE_TAG}"|' ${valuesPath}
                    """

                    sh """
                        helm upgrade --install ${HELM_RELEASE_NAME} ${env.HELM_CHART_DIR} --namespace ${HELM_NAMESPACE} --create-namespace
                    """
                }
            }
        }
    }
}
