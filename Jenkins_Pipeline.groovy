import java.text.SimpleDateFormat
import java.util.Date

def getLatestJarFileName() {
    def date = new Date()
    def formattedTime = new SimpleDateFormat("yyMMdd_HHmm").format(date)
    return "logging-sample-prj-${formattedTime}-no_db.jar"  // 수정된 JAR 파일명
}

def deployApp(targetServerIp, targetServerPort, jarFileName) {
    def deployPath = '/home/ubuntu/'
    def runAppCommand = "nohup java -jar ${deployPath}${jarFileName} > nohup.log 2>&1 &"
    
    // 서버에 파일을 SCP로 전송
    sshagent(['KDT_Project3_NHN']) { // NHN Cloud에서 발급한 키 페어의 Jenkins Credential ID
        // 기존 애플리케이션 프로세스 종료
        sh "ssh -o StrictHostKeyChecking=no -p $targetServerPort ubuntu@$targetServerIp 'ps -ef | grep java | grep -v grep | awk \'{print \$2}\' | sudo xargs kill -9 || echo \"No process found\"'"

        // 새로운 JAR 파일 배포 및 애플리케이션 시작
        sh "scp -o StrictHostKeyChecking=no -P $targetServerPort ${env.WORKSPACE}/build/custom-libs/${jarFileName} ubuntu@$targetServerIp:${deployPath}"
        sh "ssh -o StrictHostKeyChecking=no -p $targetServerPort ubuntu@$targetServerIp '$runAppCommand'"
    }
}

def rollbackApp(targetServerIp, targetServerPort) {
    def previousJarPath = 'libs/previous-log-tracking-app.jar'
    def deployPath = '/home/ubuntu/'
    def runAppCommand = "nohup java -jar ${deployPath}previous-log-tracking-app.jar > nohup.log 2>&1 &"
        
    // 이전 버전의 JAR 파일을 배포하고 애플리케이션을 시작
    sshagent(['KDT_Project3_NHN']) { // NHN Cloud에서 발급한 키 페어의 Jenkins Credential ID
        // 기존 애플리케이션 프로세스 종료
        sh "ssh -o StrictHostKeyChecking=no -p $targetServerPort ubuntu@$targetServerIp 'ps -ef | grep java | grep -v grep | awk \'{print \$2}\' | sudo xargs kill -9 || echo \"No process found\"'"

        // 이전 버전 JAR 파일 배포 및 애플리케이션 시작
        sh "scp -o StrictHostKeyChecking=no -P $targetServerPort $previousJarPath ubuntu@$targetServerIp:${deployPath}"
        sh "ssh -o StrictHostKeyChecking=no -p $targetServerPort ubuntu@$targetServerIp '$runAppCommand'"
    }
}

pipeline {
    tools {
        gradle "GRADLE" // Jenkins의 Gradle ID
    }

    agent any
    environment {
        CLONE_DIR = "${env.WORKSPACE}"
    }

    stages {
        stage('Clone') {
            steps {
                echo "저장소를 클론 중입니다..."
                git branch: 'main', url: 'https://github.com/lcl1380/log-tracking-app.git'
                echo "저장소 클론 완료. 클론된 파일 경로: ${CLONE_DIR}"
            }
        }

        stage('Build') {
            steps {
                echo "빌드 프로세스를 시작합니다..."
                sh 'chmod +x ./gradlew'
                sh './gradlew clean build'
                echo "빌드 프로세스 완료."
                script {
                    def jarFileName = getLatestJarFileName()
                    echo "빌드된 파일의 경로: ${jarFileName}"
                }
            }
        }

        stage('Test') {
            steps {
                echo "테스트 프로세스를 시작합니다..."
                sh './gradlew test'
                echo "테스트 프로세스 완료."
            }
        }
        
        stage('Deploy A-Private Instance') {
            steps {
                script {
                    try {
                        echo "A-Private Instance에 애플리케이션을 배포 중입니다..."
                        def jarFileName = getLatestJarFileName()
                        deployApp('192.168.2.53', 22, jarFileName)
                        deployApp('192.168.2.91', 22, jarFileName)
                        echo "A-Private Instance에 애플리케이션 배포 성공."
                    } catch (Exception e) {
                        echo "배포 실패, 롤백을 수행합니다..."
                        rollbackApp('192.168.2.53', 22)
                        rollbackApp('192.168.2.91', 22)
                        echo "롤백 완료."
                        throw e
                    }
                }
            }
        }
    }
    post {
        success {
            echo "배포가 성공적으로 완료되었습니다."
        }
        failure {
            echo "배포에 실패했습니다. 롤백을 수행했습니다."
        }
    }
}