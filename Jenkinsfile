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

                    sh "docker ps -q -f name=${containerName} | xargs -r docker stop"
                    sh "docker ps -a -q -f name=${containerName} | xargs -r docker rm"

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
                        sh "docker login -u $DOCKER_USER -p $DOCKER_PASS http://${DOCKER_REGISTRY}"
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

        stage('Update Helm Chart Image Tag') {
            steps {
                script {
                    def imageTag = "${IMAGE_TAG}"
                    def imageRepo = "${DOCKER_REGISTRY}/${IMAGE_NAME}"

                    // Update values.yaml with the new image tag
                    sh """
                    sed -i 's|tag:.*|tag: "${imageTag}"|' helm-chart/values.yaml
                    sed -i 's|repository:.*|repository: "${imageRepo}"|' helm-chart/values.yaml
                    """
                }
            }
        }

        stage('Package Helm Chart') {
            steps {
                script {
                    // Package the Helm chart with the image version (tag)
                    sh "helm package helm-chart/ --version ${IMAGE_TAG} --app-version ${IMAGE_TAG} --destination ."
                }
            }
        }

        stage('Push Helm Chart to Nexus') {
            steps {
                script {
                    // Get the Helm chart package filename
                    def helmChartPackage = sh(script: "ls *.tgz", returnStdout: true).trim()

                    // Push the packaged Helm chart to Nexus
                    withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIALS_ID,
                                                       usernameVariable: 'NEXUS_USER',
                                                       passwordVariable: 'NEXUS_PASS')]) {
                        sh """
                        curl -v --user $NEXUS_USER:$NEXUS_PASS \
                        --upload-file ${helmChartPackage} \
                        http://${DOCKER_REGISTRY}/repository/helm-hosted/
                        """
                    }
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
