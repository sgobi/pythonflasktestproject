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
                        sh "
