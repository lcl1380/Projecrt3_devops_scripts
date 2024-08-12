#!/bin/bash

# MySQL 접속 정보
MYSQL_HOST="ad0d8118-7b84-4379-ac3a-2983cbcf81ef.internal.kr1.mysql.rds.nhncloudservice.com"  # MySQL 서버의 엔드포인트
MYSQL_USER="log_admin_A"      # MySQL 사용자명
MYSQL_PASSWORD="mysql1380"  # MySQL 비밀번호
MYSQL_DATABASE="log_backup"   # 스키마명 (데이터베이스 이름)
MYSQL_TABLE="app_logs"      # 삽입할 테이블명

# 로그 파일
LOG_FILE="/home/ubuntu/log.log"

# 로그 파일을 한 줄씩 읽어서 처리
while IFS=$'\t' read -r type log_data user_name endpoint; do
    # 필드 값들을 확인하여 문제가 있는지 확인
    echo "Type: '$type', Date: '$log_data', User: '$user_name', Endpoint: '$endpoint'"
    
    # INSERT 쿼리 생성 및 실행
    mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -P 3306 -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "
    INSERT INTO $MYSQL_TABLE(type, log_data, user_name, endpoint)
    VALUES ('$type', '$log_data', '$user_name', '$endpoint');
    "
done < "$LOG_FILE"

# ---------------------------------------------------------------------------------------------------------
# 터미널 접속 명령어 예시 (Bastion 상에서 접근 가능)
mysql -h ad0d8118-7b84-4379-ac3a-2983cbcf81ef.internal.kr1.mysql.rds.nhncloudservice.com -P 3306 -u log_admin_A -p

# Infile Load 수행 방식
mysql --local-infile -h ad0d8118-7b84-4379-ac3a-2983cbcf81ef.internal.kr1.mysql.rds.nhncloudservice.com -P 3306 -u log_admin_A -p