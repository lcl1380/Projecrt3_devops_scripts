#!/bin/bash

# Java와 Prometheus 설치
# Java 17 설치 ----------------------------------------------------------
echo "Java 17 설치 중..."
sudo apt-get update -qq > /dev/null
sudo apt-get install -y openjdk-17-jdk -qq > /dev/null
java_version=$(java -version 2>&1 | awk -F[\"_] 'NR==1{print $2}')
echo -e "Java가 성공적으로 설치되었습니다.(버전: $java_version)\n"

# Prometheus 설치 ----------------------------------------------------------
if ! systemctl is-active --quiet prometheus; then
  echo "Prometheus 설치 중..."
  sudo apt-get update -qq > /dev/null
  sudo apt-get install -y prometheus -qq > /dev/null
  sudo systemctl start prometheus
  prometheus_status=$(sudo systemctl status prometheus | grep "Active:")
  echo -e "Prometheus가 성공적으로 설치되었습니다.\nPrometheus 상태: $prometheus_status\n"
else
  echo "Prometheus가 이미 실행 중입니다."
fi