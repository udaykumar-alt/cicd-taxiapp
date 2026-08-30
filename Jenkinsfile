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
                echo '----------- Git Checkout Started ----------'
                checkout scm
                echo '----------- Git Checkout Completed ----------'
            }
        }


        stage('Build') {
            steps {
                echo '----------- Maven Build Started ----------'

                sh '''
                    mvn clean package -DskipTests
                '''

                echo '----------- Maven Build Completed ----------'
            }
        }


        stage('Test') {
            steps {
                echo '----------- Unit Test Started ----------'

                sh '''
                    mvn test
                    mvn surefire-report:report
                '''

                echo '----------- Unit Test Completed ----------'
            }
        }


        stage('SonarCloud Analysis') {
            steps {
                echo '----------- SonarCloud Scan Started ----------'

                sh """
                    mvn verify \
                    org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                    -Dsonar.projectKey=taxi-app0001_taxi-app \
                    -Dsonar.organization=taxi-app0001 \
                    -Dsonar.host.url=https://sonarcloud.io \
                    -Dsonar.token=${SONAR_TOKEN}
                """

                echo '----------- SonarCloud Scan Completed ----------'
            }
        }


        stage('Trivy Filesystem Scan') {
            steps {
                echo '----------- Trivy Filesystem Scan Started ----------'

                sh '''
                    trivy fs . \
                    --scanners vuln,secret,misconfig \
                    --severity HIGH,CRITICAL \
                    --exit-code 1
                '''

                echo '----------- Trivy Filesystem Scan Completed ----------'
            }
        }


        stage('Terraform Format Check') {
            steps {
                dir('terraform_files') {
                    sh '''
                        terraform fmt -check
                    '''
                }
            }
        }


        stage('Terraform Init') {
            steps {
                dir('terraform_files') {
                    sh '''
                        terraform init
                    '''
                }
            }
        }


        stage('Terraform Validate') {
            steps {
                dir('terraform_files') {
                    sh '''
                        terraform validate
                    '''
                }
            }
        }


        stage('Terraform Plan') {
            steps {
                dir('terraform_files') {
                    sh '''
                        terraform plan -out=tfplan
                    '''
                }
            }
        }


        stage('Jar Publish') {
            steps {
                script {

                    echo '----------- Jar Publish Started ----------'

                    def server = Artifactory.newServer(
                        url: registry,
                        credentialsId: 'jfrog-cred'
                    )

                    def properties = "buildid=${env.BUILD_ID}"

                    def uploadSpec = """{
                        "files": [
                            {
                                "pattern": "target/(*)",
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

                    echo '----------- Jar Publish Completed ----------'
                }
            }
        }


        stage('Docker Build') {
            steps {
                script {

                    echo '----------- Docker Build Started ----------'

                    app = docker.build(
                        "${imageName}:1.0.${env.BUILD_NUMBER}"
                    )

                    echo '----------- Docker Build Completed ----------'
                }
            }
        }


        stage('Trivy Docker Image Scan') {
            steps {

                echo '----------- Trivy Docker Image Scan Started ----------'

                sh """
                    trivy image \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    ${imageName}:1.0.${env.BUILD_NUMBER}
                """

                echo '----------- Trivy Docker Image Scan Completed ----------'
            }
        }


        stage('Docker Publish') {
            steps {
                script {

                    echo '----------- Docker Publish Started ----------'

                    docker.withRegistry(
                        registry,
                        'jfrog-cred'
                    ) {
                        app.push()
                    }

                    echo '----------- Docker Publish Completed ----------'
                }
            }
        }


        stage('Terraform Apply') {
            steps {

                input message: 'Do you want to deploy Terraform infrastructure?'

                dir('terraform_files') {

                    sh '''
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

    }
}
