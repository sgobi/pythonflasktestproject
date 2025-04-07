// pipeline {
//     agent any

//     stages {
//         stage('Clone Repository') {
//             steps {
//                 // Pull the Flask app from Git
//                 git url: 'https://github.com/sgobi/pythonflasktestproject.git', branch: 'main'
//             }
//         }

//         stage('Stop and Remove Old Container and Image') {
//             steps {
//                 script {
//                     // Get the name of the last container that was running the app
//                     def containerName = "flask-app"

//                     // Stop the container if it's running
//                     sh "docker ps -q -f name=${containerName} | xargs -r docker stop"

//                     // Remove the container if it exists
//                     sh "docker ps -a -q -f name=${containerName} | xargs -r docker rm"

//                     // Remove the previous image (if exists)
//                     def oldImage = sh(script: "docker images -q my-flask-app", returnStdout: true).trim()
//                     if (oldImage) {
//                         sh "docker rmi -f ${oldImage}"
//                     }
//                 }
//             }
//         }

//         stage('Build Docker Image on Host') {
//             steps {
//                 // Build Docker image on the host with a tag that includes the Jenkins build number
//                 script {
//                     def imageTag = "my-flask-app:${env.BUILD_NUMBER}"
//                     sh "docker build -t ${imageTag} ."
//                 }
//             }
//         }

//         stage('Run Docker Container on Host') {
//             steps {
//                 // Run the Flask app container on the host
//                 script {
//                     def imageTag = "my-flask-app:${env.BUILD_NUMBER}"
//                     sh "docker run -d -p 5000:5000 --name flask-app ${imageTag}"
//                 }
//             }
//         }
//     }
// }






pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "192.168.1.10:8082"
        IMAGE_NAME = "my-flask-app"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'docker-creds' // Jenkins credentials ID (Username + Password)
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

