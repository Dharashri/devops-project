// ─────────────────────────────────────────────
//  Jenkinsfile
//  End-to-End CI/CD Pipeline
//  Stages: Checkout → Build Docker Image → (optional) Push → Archive
// ─────────────────────────────────────────────

pipeline {

    // Run on the Jenkins agent that has Docker installed
    agent {
        label 'devops-agent'
    }

    environment {
        IMAGE_NAME  = "prt-devops-app"
        IMAGE_TAG   = "latest"
        // If pushing to a registry, set REGISTRY e.g. "docker.io/youruser"
        // REGISTRY = credentials('docker-hub-creds')
    }

    stages {

        // ── Stage 1: Pull source code from Git ────────────────────
        stage('Checkout') {
            steps {
                echo '>>> Checking out source code from Git...'
                checkout scm
            }
        }

        // ── Stage 2: Build Docker Image ────────────────────────────
        stage('Build Docker Image') {
            steps {
                echo ">>> Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        // ── Stage 3: Verify Image ──────────────────────────────────
        stage('Verify Image') {
            steps {
                echo '>>> Listing local Docker images...'
                sh 'docker images | grep ${IMAGE_NAME}'
            }
        }

        // ── Stage 4: Smoke Test (run container, check HTTP 200) ────
        stage('Smoke Test') {
            steps {
                echo '>>> Running smoke test on built image...'
                sh """
                    docker run -d --name smoke-test -p 8099:80 ${IMAGE_NAME}:${IMAGE_TAG}
                    sleep 3
                    curl -f http://localhost:8099 || exit 1
                    docker stop smoke-test && docker rm smoke-test
                """
            }
        }

        // ── Stage 5: (Optional) Push to Registry ──────────────────
        // Uncomment and configure REGISTRY + credentials to push
        /*
        stage('Push to Registry') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }
        */
    }

    post {
        success {
            echo '✅ Pipeline completed successfully! Docker image is ready.'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs above.'
        }
        always {
            echo '>>> Cleaning up any dangling smoke-test containers...'
            sh 'docker rm -f smoke-test 2>/dev/null || true'
        }
    }
}
