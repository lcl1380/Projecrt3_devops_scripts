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

# 배치 크기 설정
BATCH_SIZE=1000

# 파일이 존재하는지 확인
if [[ -f "$LOG_FILE" ]]; then
    # 쿼리 준비
    query_prefix="INSERT INTO $MYSQL_TABLE (log_level, timestamp, endpoint, http_method, user_id, session_id, response_time, status_code, content_length, source_ip, user_agent) VALUES "
    query_values=""
    count=0

    while IFS=$'\t' read -r log_level timestamp endpoint http_method user_id session_id response_time status_code content_length source_ip user_agent; do
        # 각 레코드를 쿼리 형태로 추가
        query_values="$query_values('$log_level', '$timestamp', '$endpoint', '$http_method', '$user_id', '$session_id', '$response_time', '$status_code', '$content_length', '$source_ip', '$user_agent'),"

        # 카운트 증가
        ((count++))

        # BATCH_SIZE만큼 모이면 쿼리 실행
        if (( count % BATCH_SIZE == 0 )); then
            # 마지막 콤마 제거 및 쿼리 실행
            query="${query_prefix}${query_values%,};"
            mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -P 3306 -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "$query"

            # 변수 초기화
            query_values=""
        fi
    done < "$LOG_FILE"

    # 남아있는 레코드가 있으면 마지막으로 한 번 더 실행
    if [[ -n "$query_values" ]]; then
        # 마지막 콤마 제거 및 쿼리 실행
        query="${query_prefix}${query_values%,};"
        mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -P 3306 -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "$query"
    fi
else
    echo "Log file not found: $LOG_FILE"
fi
