#!/bin/bash

# public instance 세팅 용도 : Java, Jenkin, Nginx, Prometheus, Grafana 설치 자동화
# Java 17 설치 ----------------------------------------------------------
echo "Java 17 설치 중..."
sudo apt-get update -qq > /dev/null
sudo apt-get install -y openjdk-17-jdk -qq > /dev/null
java_version=$(java -version 2>&1 | awk -F[\"_] 'NR==1{print $2}')
echo -e "Java가 성공적으로 설치되었습니다.(버전: $java_version)\n"

# Jenkins 설치 ----------------------------------------------------------
if ! systemctl is-active --quiet jenkins; then
  echo "Jenkins 설치 중..."
  curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
  echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
  sudo apt-get update -qq > /dev/null
  sudo apt-get install -y jenkins -qq > /dev/null
  sudo systemctl start jenkins
  jenkins_status=$(sudo systemctl status jenkins | grep "Active:")
  echo -e "Jenkins가 성공적으로 설치되었습니다.\nJenkins 상태: $jenkins_status\n"
else
  echo "Jenkins가 이미 실행 중입니다."
fi

# Nginx 설치 ----------------------------------------------------------
if ! systemctl is-active --quiet nginx; then
  echo "Nginx 설치 중..."
  sudo apt-get update -qq > /dev/null
  sudo apt-get install -y curl gnupg2 ca-certificates lsb-release -qq > /dev/null
  sudo apt-get install -y ubuntu-keyring -qq > /dev/null
  curl -s https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
  gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
  sudo apt-get update -qq > /dev/null
  sudo apt-get install -y nginx -qq > /dev/null
  nginx_version=$(nginx -v 2>&1)
  sudo systemctl start nginx
  nginx_status=$(sudo systemctl status nginx | grep "Active:")
  echo -e "Nginx가 성공적으로 설치되었습니다.\n$nginx_version\nNginx 상태: $nginx_status\n"
else
  echo "Nginx가 이미 실행 중입니다."
fi

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

# Grafana 설치 ----------------------------------------------------------
if ! systemctl is-active --quiet grafana-server; then
  echo "Grafana 설치 중..."
  sudo apt-get install -y apt-transport-https gnupg2 curl -qq > /dev/null
  curl https://packages.grafana.com/gpg.key | sudo apt-key add -qq > /dev/null
  echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
  sudo apt-get update -qq > /dev/null
  sudo apt-get install -y grafana -qq > /dev/null
  sudo systemctl start grafana-server
  grafana_status=$(sudo systemctl status grafana-server | grep "Active:")
  echo -e "Grafana가 성공적으로 설치되었습니다.\nGrafana 상태: $grafana_status\n"
else
  echo "Grafana가 이미 실행 중입니다."
fi