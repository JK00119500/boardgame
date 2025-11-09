pipeline {
    agent any

    tools {   
        maven 'Maven3'
        jdk 'JDK17'
        docker 'docker'
    }

    environment {
        DOCKERHUB_CREDENTIALS = "docker_hub_cred"
        DOCKERHUB_REPO = "jayu3110/boardgame-listing"
        IMAGE_NAME = "boardgame-listing"
        SONARQUBE_ENV = 'MySonarQubeServer' 
        BASTION_HOST = 'ec2-13-229-47-163.ap-southeast-1.compute.amazonaws.com'
        BASTION_USER = 'ec2-user'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/JK00119500/boardgame.git'
            }
        }
        stage('Build') {
            steps {
                sh '''
                mvn clean install -DskipTests
                '''
            }
        }
        stage('Build Docker Image') {
            steps {
                sh "pwd"
                sh "ls -lrt"
                sh "docker build --no-cache -t ${IMAGE_NAME}:latest ."
                sh "ls -lrt target"
                sh "docker tag ${IMAGE_NAME}:latest ${DOCKERHUB_REPO}:latest"
            }
        }
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker push ${DOCKERHUB_REPO}:latest
                    '''
                }
            }
        }
        // stage('Trivy scan') {
        //     steps {
        //         sh '''
        //         docker run --rm --name trivy-cli \
        //     -v /var/run/docker.sock:/var/run/docker.sock \
        //     -v $(which docker):/usr/bin/docker \
        //     -u root \
        //     -e DOCKER_GID=$(getent group docker | cut -d: -f3) \
        //     aquasec/trivy:latest image \
        //     ${IMAGE_NAME}
        //     '''
        // }}
        // stage('SonarQube Analysis') {
        //     steps {
        //         withSonarQubeEnv("${SONARQUBE_ENV}") {
        //             sh "mvn clean verify sonar:sonar -Dsonar.projectKey=Boardgame -Dsonar.projectName='Boardgame'"
        //         }
        //     }
        // }
        stage('OWASP Dependency-Check Vulnerabilities') {
            steps {
            dependencyCheck additionalArguments: ''' 
                    -o './'
                    -s './'
                    -f 'ALL' 
                    --prettyPrint''', odcInstallation: 'owasp-DC'
            dependencyCheckPublisher pattern: 'dependency-check-report.xml'   
            }
        }
        stage('Sanity: SSH to EKS Jump') {
            steps {
                sshagent(credentials: ['eks_jump_ssh']) {
                    sh '''
                    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                    ${BASTION_USER}@${BASTION_HOST} 'hostname && whoami && aws --version || true'
                    '''
                    }
                    }
                    }
        stage('app deploy on eks'){
        steps{
            sshagent(credentials: ['eks_jump_ssh']) {
            
            sh '''
                ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                ${BASTION_USER}@${BASTION_HOST} 'sudo su root && whoami && aws eks update-kubeconfig --name boardgame-eks-cluster --region ap-southeast-1 && kubectl create ns capstone --dry-run=client -o yaml | kubectl apply -f - && kubectl apply -f /opt/app-files/deployment.yaml -n capstone && kubectl rollout restart deployment.apps/boardgame-app -n capstone
                '
                '''
            }
        }
    }
}}
