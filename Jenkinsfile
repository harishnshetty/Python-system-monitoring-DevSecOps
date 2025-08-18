pipeline {
    agent any

    tools {
        jdk 'jdk17'
            }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {
        stage("Clean Workspace") {
            steps {
                cleanWs()
            }
        }

        stage("Git Checkout") {
            steps {
                git branch: 'main', url: 'https://github.com/harishnshetty/system-monitoring-devsecops.git'
            }
        }

        stage("SonarQube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=sys-monitor-python \
                        -Dsonar.projectKey=sys-monitor-python '''
                }
            }
        }

        stage("Quality Gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }

        stage("Install Python Dependencies") {
            steps {
                sh "pip install -r /src/requirements.txt"
            }
        }
                    
        
        // stage("OWASP FS Scan") {
        //     steps {
        //         dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit',
        //                         odcInstallation: 'dp-check'
        //         dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        //     }
        // }  

        
        // https://nvd.nist.gov/developers/request-an-api-key  [request an API key]
        stage("OWASP FS Scan") {
            steps {
                dependencyCheck additionalArguments: '''
                    --scan ./ 
                    --disableYarnAudit 
                    --disableNodeAudit 
                    --nvdApiKey 788b28b3-e0a8-4fcf-a6c7-a6c4b772d8a7  
                    ''',
                odcInstallation: 'dp-check'

                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }


        stage("Trivy File Scan") {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }

        stage("Build Docker Image") {
            steps {
                script {
                    env.IMAGE_TAG = "harishnshetty/sys-monitor-python:${BUILD_NUMBER}"

                    // Optional cleanup
                    sh "docker rmi -f sys-monitor-python ${env.IMAGE_TAG} || true"

                    sh "docker build -t sys-monitor-python ."
                }
            }
        }

        stage("Tag & Push to DockerHub") {
            steps {
                script {
                    withCredentials([string(credentialsId: 'docker-cred', variable: 'dockerpwd')]) {
                        sh "docker login -u harishnshetty -p ${dockerpwd}"
                        sh "docker tag sys-monitor-python ${env.IMAGE_TAG}"
                        sh "docker push ${env.IMAGE_TAG}"

                        // Also push latest
                        sh "docker tag sys-monitor-python harishnshetty/sys-monitor-python:latest"
                        sh "docker push harishnshetty/sys-monitor-python:latest"
                    }
                }
            }
        }

       

        stage("Trivy Scan Image") {
            steps {
                script {
                    sh """
                    echo '🔍 Running Trivy scan on ${env.IMAGE_TAG}'

                    # JSON report
                    trivy image -f json -o trivy-image.json ${env.IMAGE_TAG}

                    # HTML report using built-in HTML format
                    trivy image -f table -o trivy-image.txt ${env.IMAGE_TAG}

                    # Fail build if HIGH/CRITICAL vulnerabilities found
                    # trivy image --exit-code 1 --severity HIGH,CRITICAL ${env.IMAGE_TAG} || true
                """
                }
            }
        }


        stage("Deploy to Container") {
            steps {
                script {
                    sh "docker rm -f sys-monitor-python || true"
                    sh "docker run -d --name sys-monitor-python -p 80:3000 ${env.IMAGE_TAG}"
                }
            }
        }
    }

      post {
    always {
        script {
            def buildStatus = currentBuild.currentResult
            def buildUser = currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')[0]?.userId ?: ' Github User'

            emailext (
                subject: "Pipeline ${buildStatus}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <p>This is a Jenkins sys-monitor-python CICD pipeline status.</p>
                    <p>Project: ${env.JOB_NAME}</p>
                    <p>Build Number: ${env.BUILD_NUMBER}</p>
                    <p>Build Status: ${buildStatus}</p>
                    <p>Started by: ${buildUser}</p>
                    <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                """,
                to: 'harishn662@gmail.com',
                from: 'harishn662@gmail.com',
                mimeType: 'text/html',
                attachmentsPattern: 'trivyfs.txt,trivy-image.json,trivy-image.txt,dependency-check-report.xml'
                    )
        }
    }
}
}




