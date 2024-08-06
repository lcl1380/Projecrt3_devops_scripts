def deployApp(targetServerIp, targetServerPort) {
    def jarPath = 'build/custom-libs/logging-sample-prj-240806_1335-no_db.jar'
    def deployPath = '/home/ubuntu'
    def runAppCommand = "nohup java -jar $deployPath/logging-sample-prj-240806_1335-no_db.jar > nohup.log 2>&1 &"
    def checkLogCommand = "grep -q 'Started logging-sample-prj in' $deployPath/nohup.log"
    def checkProcessCommand = "pgrep -f logging-sample-prj-240806_1335-no_db.jar"
        
    // 서버에 파일을 SCP로 전송
    sshagent(['KDT_Project3_NHN']) { // 이 부분에서 'KDT_Project3_NHN'는 Jenkins에 등록한 Credential ID (NHN에서 발급한 키 페어)
        // 기존 애플리케이션 프로세스 종료
        sh "ssh -o StrictHostKeyChecking=no -p $targetServerPort ubuntu@$targetServerIp 'ps -ef | grep java | grep -v grep | awk \'{print \$2}\' | sudo xargs kill -9 || echo \"No process found\"'"

        // 새로운 JAR 파일 배포 및 애플리케이션 시작
        sh "scp -o StrictHostKeyChecking=no -P $targetServerPort $jarPath ubuntu@$targetServerIp:$deployPath/"
        sh "ssh -o StrictHostKeyChecking=no -p $targetServerPort ubuntu@$targetServerIp '$runAppCommand'"
    }
}

def rollbackApp(targetServerIp, targetServerPort) {
    def previousJarPath = 'build/libs/previous-logging-sample-prj-0.0.1-SNAPSHOT.jar'
    def deployPath = '/home/ubuntu'
    def runAppCommand = "nohup java -jar $deployPath/previous-inclass-spring-security-0.0.1-SNAPSHOT.jar > nohup.log 2>&1 &"
        
    // 이전 버전의 JAR 파일을 배포하고 애플리케이션을 시작
    sshagent(['KDT_Project3_NHN']) { // 이 부분에서 'KDT_Project3_NHN'는 Jenkins에 등록한 Credential ID (NHN에서 발급한 키 페어)
        // 기존 애플리케이션 프로세스 종료
        sh "ssh -o StrictHostKeyChecking=no -p $targetServerPort ubuntu@$targetServerIp 'ps -ef | grep java | grep -v grep | awk \'{print \$2}\' | sudo xargs kill -9 || echo \"No process found\"'"

        // 이전 버전 JAR 파일 배포 및 애플리케이션 시작
        sh "scp -o StrictHostKeyChecking=no -P $targetServerPort $previousJarPath ubuntu@$targetServerIp:$deployPath/"
        sh "ssh -o StrictHostKeyChecking=no -p $targetServerPort ubuntu@$targetServerIp '$runAppCommand'"
    }
}

pipeline {
    tools {
        gradle "GRADLE" // Jenkins에서 설정한 Gradle의 이름
    }

    agent any
    stages {
        stage('Clone') {
            steps { // main인지 master인지 확인하고 Pipeline Syntax 돌려서 이중으로 확인해보기
                git branch: 'main', url: 'https://github.com/lcl1380/KDT_Project3.git'
            }
        }

        stage('Build') {
            steps {
                sh 'chmod +x ./gradlew'
                sh './gradlew clean build'
            }
        }
        
        stage('Test') {
            steps {
                script {
                    sh './gradlew test'
                }
            }
        }
        
        stage('Deploy A-Private Instance') {
            steps {
                script {
                    try {
                        // 첫 번째 인스턴스로 배포
                        deployApp('192.168.2.31', 22)
                        // 두 번째 인스턴스로 배포
                        // deployApp('192.168.2.32', 22)
                    } catch (Exception e) {
                        // 오류 발생 시 롤백
                        rollbackApp('192.168.2.31', 22)
                        // rollbackApp('192.168.2.32', 22)
                        throw e
                    }
                }
            }
        }
        
        // stage('Deploy B-Private Instance') {
        //     steps {
        //         script {
        //             try {
        //                 // 첫 번째 인스턴스로 배포
        //                 deployApp('192.168.5.31', 22))
        //                 // 두 번째 인스턴스로 배포
        //                 deployApp('192.168.2.32', 22)
        //             } catch (Exception e) {
        //                 // 오류 발생 시 롤백
        //                 rollbackApp('192.168.5.31', 22)
        //                 rollbackApp('192.168.5.32', 22)
        //                 throw e
        //             }
        //         }
        //     }
        // }
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