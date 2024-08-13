#!/bin/bash

# MySQL 접속 정보
MYSQL_HOST="ad0d8118-7b84-4379-ac3a-2983cbcf81ef.internal.kr1.mysql.rds.nhncloudservice.com"
MYSQL_USER="log_admin_A"
MYSQL_PASSWORD="mysql1380"
MYSQL_DATABASE="log_backup"
MYSQL_TABLE="application_logs"

# 로그 파일 디렉터리 및 파일 경로
LOG_DIR="/home/ubuntu/filter_logs"
LOG_DATE=$(date '+%Y-%m-%d')
LOG_FILE="$LOG_DIR/$LOG_DATE/${LOG_DATE}_merged.log"

# 파일이 존재하는지 확인
if [[ -f "$LOG_FILE" ]]; then
    while IFS=$'\t' read -r log_level timestamp endpoint http_method user_id session_id response_time status_code content_length source_ip user_agent; do
        # INSERT 쿼리 생성 및 실행
        mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -P 3306 -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "
        INSERT INTO $MYSQL_TABLE(log_level, timestamp, endpoint, http_method, user_id, session_id, response_time, status_code, content_length, source_ip, user_agent)
        VALUES ('$log_level', '$timestamp', '$endpoint', '$http_method', '$user_id', '$session_id', '$response_time', '$status_code', '$content_length', '$source_ip', '$user_agent');
        "
    done < "$LOG_FILE"
else
    echo "Log file not found: $LOG_FILE"
fi


# ---------------------------------------------------------------------------------------------------------
# 터미널 접속 명령어 예시 (Bastion 상에서 접근 가능)
mysql -h ad0d8118-7b84-4379-ac3a-2983cbcf81ef.internal.kr1.mysql.rds.nhncloudservice.com -P 3306 -u log_admin_A -p