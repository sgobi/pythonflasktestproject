pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "192.168.1.10:8082"
        IMAGE_NAME = "my-flask-app"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'docker-nexus-artifactory-repo-creds' // Jenkins credentials ID (Username + Password)
    }

    stages {
        stage('Clone Repository') {
            steps {
                git url: 'https://github.com/sgobi/pythonflasktestproject.git', branch: 'main'
            }
        }

        stage('Stop and Remove Old Container and Image') {
            steps {
                script {
                    def containerName = "flask-app"

                    // Stop running container if it exists
                    sh "docker ps -q -f name=${containerName} | xargs --no-run-if-empty docker stop"
                    // Remove stopped container if it exists
                    sh "docker ps -a -q -f name=${containerName} | xargs --no-run-if-empty docker rm"

                    // Remove old image if it exists
                    def oldImage = sh(script: "docker images -q ${IMAGE_NAME}", returnStdout: true).trim()
                    if (oldImage) {
                        sh "docker rmi -f ${oldImage}"
                    }
                }
            }
        }

        stage('Build Docker Image on Host') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Login to Artifactory Docker Registry') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIALS_ID,
                                                     usernameVariable: 'DOCKER_USER',
                                                     passwordVariable: 'DOCKER_PASS')]) {
                        // Secure login using --password-stdin
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

        stage('Run Docker Container on Host') {
            steps {
                script {
                    def fullImageName = "${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker run -d -p 5000:5000 --name flask-app ${fullImageName}"
                }
            }
        }
    }
}
