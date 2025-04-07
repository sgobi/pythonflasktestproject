pipeline {
    agent any

    stages {
        stage('Clone Repository') {
            steps {
                // Pull the Flask app from Git
                git url: 'https://github.com/sgobi/pythonflasktestproject.git', branch: 'main'
            }
        }

        stage('Build Docker Image on Host') {
            steps {
                // Run docker build on the host machine
                script {
                    sh 'docker build -t my-flask-app .'
                }
            }
        }

        stage('Run Docker Container on Host') {
            steps {
                // Run the Flask app container on the host
                script {
                    sh 'docker run -d -p 5000:5000 --name flask-app my-flask-app'
                }
            }
        }
    }
}
