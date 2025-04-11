pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "192.168.1.10:8082"
        IMAGE_NAME = "my-flask-app"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'docker-nexus-artifactory-repo-creds'
        HELM_CHART_DIR = "/var/jenkins_home/workspace/myApp/my-flask-app"
        HELM_REPO_URL = "http://192.168.1.10:8081/repository/myprojecthelmc/"
        HELM_CHART_NAME = "my-flask-app"
        HELM_NAMESPACE = "default"
        HELM_ARTIFACTORY_CREDS = 'nexus-helm-credentials'
        VERSION = "1.0.${env.BUILD_NUMBER}" // Semantic versioning, using BUILD_NUMBER for patch version
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
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Login to Docker Registry') {
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

        stage('Package and Upload Helm Chart') {
            steps {
                script {
                    // Package the Helm chart
                    dir(env.HELM_CHART_DIR) {
                        sh "helm package . --version ${env.VERSION}"
                    }

                    def chartTgz = "${HELM_CHART_DIR}/${HELM_CHART_NAME}-${env.VERSION}.tgz"
                    echo "Helm chart packaged at: ${chartTgz}"

                    // Upload the packaged Helm chart to Nexus repository
                    withCredentials([usernamePassword(
                        credentialsId: env.HELM_ARTIFACTORY_CREDS,
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )]) {
                        sh """
                            curl -u \$NEXUS_USER:\$NEXUS_PASS --upload-file ${chartTgz} ${HELM_REPO_URL}${HELM_CHART_NAME}-${env.VERSION}.tgz
                        """
                    }
                }
            }
        }
    }
}
