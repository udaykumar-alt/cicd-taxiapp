def registry = 'https://taxiappj7.jfrog.io/artifactory'
def imageName = 'taxiappj7.jfrog.io/taxiapp-docker-local/taxiapp'
def app

pipeline {

    agent {
        node {
            label 'maven'
        }
    }

    environment {
        SONAR_TOKEN = credentials('SONAR_TOKEN')
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh '''
                    mvn clean package -DskipTests
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    mvn test
                    mvn surefire-report:report
                '''
            }
        }

        stage('SonarCloud Analysis') {
            steps {
                sh """
                    mvn verify \
                    org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                    -Dsonar.projectKey=taxi-app0001_taxi-app \
                    -Dsonar.organization=taxi-app0001 \
                    -Dsonar.host.url=https://sonarcloud.io \
                    -Dsonar.token=${SONAR_TOKEN}
                """
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh '''
                    trivy fs . \
                    --scanners vuln,secret,misconfig \
                    --severity HIGH,CRITICAL \
                    --exit-code 1
                '''
            }
        }

        stage('Terraform Format Check') {
            steps {
                dir('terraform_files') {
                    sh 'terraform fmt -check'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform_files') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform_files') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform_files') {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Jar Publish') {
            steps {
                script {

                    def server = Artifactory.newServer(
                        url: registry,
                        credentialsId: 'jfrog-cred'
                    )

                    def properties = "buildid=${env.BUILD_ID}"

                    def uploadSpec = """{
                        "files": [
                            {
                                "pattern": "taxi-booking/target/(*)",
                                "target": "taxiapp-libs-release-local/{1}",
                                "flat": "false",
                                "props": "${properties}",
                                "exclusions": [
                                    "*.sha1",
                                    "*.md5"
                                ]
                            }
                        ]
                    }"""

                    def buildInfo = server.upload(uploadSpec)
                    buildInfo.env.collect()
                    server.publishBuildInfo(buildInfo)
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    app = docker.build(
                        "${imageName}:1.0.${env.BUILD_NUMBER}"
                    )
                }
            }
        }

        stage('Trivy Docker Image Scan') {
            steps {
                sh """
                    trivy image \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    ${imageName}:1.0.${env.BUILD_NUMBER}
                """
            }
        }

        stage('Docker Publish') {
            steps {
                script {
                    docker.withRegistry(
                        registry,
                        'jfrog-cred'
                    ) {
                        app.push()
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {

                input message: 'Do you want to deploy Terraform infrastructure?'

                dir('terraform_files') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

    }
}
