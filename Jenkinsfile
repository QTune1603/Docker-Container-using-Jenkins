pipeline {
    agent any

    environment {
        IMAGE_NAME     = "hello-world-app"
        CONTAINER_NAME = "webapp-container"
        HOST_PORT      = "8087"
        CONTAINER_PORT = "8080"
    }

    stages {
        stage('Clone Source Code') {
            steps {
                echo 'Checking out source code from Git...'
                checkout scm
            }
        }

        stage('Build Application') {
            steps {
                echo 'Compiling and packaging Java application using Maven...'
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Docker Build Image') {
            steps {
                echo 'Building Docker image from Dockerfile...'
                sh "docker build -t ${IMAGE_NAME}:latest ."
            }
        }

        stage('Deploy Application') {
            steps {
                echo 'Deploying application to Docker Container...'
                script {
                    // Stop and clean up any pre-existing container with the same name
                    sh """
                        if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
                            echo "Stopping and removing existing container: ${CONTAINER_NAME}"
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true
                        fi
                    """
                    
                    // Launch the new container
                    sh "docker run -d --name ${CONTAINER_NAME} -p ${HOST_PORT}:${CONTAINER_PORT} ${IMAGE_NAME}:latest"
                }
            }
        }
    }

    post {
        success {
            echo "------------------------------------------------------------"
            echo "SUCCESS: Application is live at http://<SERVER_IP>:${HOST_PORT}/"
            echo "------------------------------------------------------------"
        }
        failure {
            echo "------------------------------------------------------------"
            echo "FAILURE: Pipeline failed. Please check build console logs."
            echo "------------------------------------------------------------"
        }
    }
}
