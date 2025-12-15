pipeline {
    agent any
    stages {
        stage('Build & Test Backend') {
            when {
                branch 'main'
                changeset "backend/**" // rulează doar dacă s-au modificat fișiere în backend
            }
            steps {
                dir('backend') {
                    sh 'mvn clean package'
                    sh 'mvn test'
                }
            }
        }

        stage('Build & Test Frontend') {
            when {
                branch 'main'
                changeset "frontend/**" // rulează doar dacă s-au modificat fișiere în frontend
            }
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm run build'
                    sh 'npm test'
                }
            }
        }

        stage('Deploy Backend') {
            when {
                branch 'main'
                changeset "backend/**"
            }
            steps {
                echo 'Deploy backend...'
                // sh './deploy-backend.sh'
            }
        }

        stage('Deploy Frontend') {
            when {
                branch 'main'
                changeset "frontend/**"
            }
            steps {
                echo 'Deploy frontend...'
                // sh './deploy-frontend.sh'
            }
        }
    }

    post {
        success { echo 'Pipeline complet executat cu succes!' }
        failure { echo 'Pipeline eșuat :(' }
        cleanWs()
    }
}