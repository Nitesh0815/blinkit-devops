pipeline {
    agent any

    environment {
        DOCKER_IMAGE   = "YOUR_DOCKERHUB_USERNAME/blinkit-app"
        DOCKER_TAG     = "latest"
        CONTAINER_NAME = "blinkit-container"
        APP_PORT       = "80"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Pulling latest code from GitHub...'
                checkout scm
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ./app"
            }
        }

        stage('Docker Push') {
            steps {
                echo 'Pushing image to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }

        stage('Deploy') {
            steps {
                echo 'Stopping old container and deploying new one...'
                sh """
                    docker stop ${CONTAINER_NAME}   || true
                    docker rm   ${CONTAINER_NAME}   || true
                    docker pull ${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker run -d \
                        --name ${CONTAINER_NAME} \
                        --restart always \
                        -p ${APP_PORT}:80 \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}
                """
            }
        }

        stage('Verify') {
            steps {
                sh "docker ps | grep ${CONTAINER_NAME}"
                echo "App is live at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):${APP_PORT}"
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully. Blinkit app is running."
        }
        failure {
            echo "Pipeline failed. Check the logs above."
        }
    }
}