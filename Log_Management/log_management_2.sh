#!/bin/bash

# 1. 로그 파일의 원본이 보관된 디렉토리 설정
log_backup_dir="/home/ubuntu/logs"

# 2. 작업을 수행할 디렉토리 설정 (2차 백업 및 편집 작업을 위한 경로)
working_dir="/home/ubuntu/backup_logs"
mkdir -p "$working_dir"  # 디렉토리가 없으면 생성

# 3. 작업할 날짜 자동 설정 (log_backup_dir의 .log 파일에서 YYYY-MM-DD 추출)
first_log_file=$(ls "$log_backup_dir"/logcontroller.*.log | head -n 1)
target_date=$(basename "$first_log_file" | cut -d'.' -f2)

# 추출된 날짜 확인
if [ -z "$target_date" ]; then
    echo "로그 파일에서 날짜를 추출할 수 없습니다."
    exit 1
fi

# 4. 작업할 로그 파일들을 작업 디렉토리로 이동 및 해당 날짜별로 정리
mkdir -p "$working_dir/$target_date"
mv "$log_backup_dir"/logcontroller."$target_date"_*.log "$working_dir/$target_date"/

# 5. 로그 파일을 필터링한 후, 필터링 완료된 로그 파일을 저장할 디렉토리 설정
filtered_log_dir="/home/ubuntu/filter_logs" 
mkdir -p "$filtered_log_dir/$target_date"

# 6. 각 로그 파일을 순회하면서 특정 패턴으로 필터링하고, 원본 파일은 삭제
for logfile in "$working_dir/$target_date"/logcontroller.*.log; do
    filename=$(basename "$logfile")
    
    # 로그 파일에서 l, v, c, o로 시작하는 라인만 필터링하여 저장
    grep '^[l|v|c|o]' "$logfile" > "$filtered_log_dir/$target_date/$filename"
    
    echo "$logfile 필터링 완료"
    rm "$logfile"  # 원본 파일 삭제
done

# 7. 필터링된 로그 파일들을 하나의 파일로 병합
merged_log_file="$filtered_log_dir/${target_date}_merged.log"
touch "$merged_log_file"

# 필터링된 각 로그 파일을 병합한 후, 개별 파일은 삭제
for logfile in "$filtered_log_dir/$target_date"/*; do
    cat "$logfile" >> "$merged_log_file"
    echo "$logfile 병합 완료"
    rm "$logfile"  # 개별 파일 삭제
done

# 최종 병합된 로그 파일의 경로 출력
echo "최종 병합된 로그 파일: $merged_log_file"