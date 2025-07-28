#!/bin/bash
# AWX 프로젝트 설정 도우미 스크립트

AWX_URL="${AWX_URL:-http://localhost:8052}"
AWX_USERNAME="${AWX_USERNAME:-admin}"
AWX_PASSWORD="${AWX_PASSWORD:-password}"

echo "=== AWX 프로젝트 설정 도우미 ==="
echo "AWX URL: $AWX_URL"

# AWX CLI 설치 확인
if ! command -v awx &> /dev/null; then
    echo "AWX CLI가 설치되지 않았습니다. 설치 중..."
    pip3 install awxkit
fi

# AWX 로그인
echo "1. AWX 로그인 중..."
awx --conf.host "$AWX_URL" --conf.username "$AWX_USERNAME" --conf.password "$AWX_PASSWORD" --conf.insecure me

# 프로젝트 생성
echo "2. 프로젝트 생성 중..."
PROJECT_ID=$(awx --conf.host "$AWX_URL" --conf.username "$AWX_USERNAME" --conf.password "$AWX_PASSWORD" --conf.insecure \
    projects create \
    --name "베어메탈 서버 자동화" \
    --description "베어메탈 서버 OS 설치, 펌웨어 업그레이드, 드라이버 설치 자동화" \
    --scm_type git \
    --scm_url "https://github.com/your-org/baremetal-server-automation.git" \
    --scm_branch main \
    --scm_update_on_launch true \
    --format json | jq -r '.id')

echo "프로젝트 ID: $PROJECT_ID"

# 인벤토리 생성
echo "3. 인벤토리 생성 중..."
INVENTORY_ID=$(awx --conf.host "$AWX_URL" --conf.username "$AWX_USERNAME" --conf.password "$AWX_PASSWORD" --conf.insecure \
    inventory create \
    --name "베어메탈 서버" \
    --description "베어메탈 서버 인벤토리" \
    --organization 1 \
    --format json | jq -r '.id')

echo "인벤토리 ID: $INVENTORY_ID"

# 인벤토리 소스 생성  
echo "4. 인벤토리 소스 생성 중..."
awx --conf.host "$AWX_URL" --conf.username "$AWX_USERNAME" --conf.password "$AWX_PASSWORD" --conf.insecure \
    inventory_sources create \
    --name "Production Inventory" \
    --inventory "$INVENTORY_ID" \
    --source scm \
    --source_project "$PROJECT_ID" \
    --source_path "inventories/production.ini" \
    --update_on_launch true

# Job Template 생성
echo "5. Job Template 생성 중..."

# 메인 설정 템플릿
awx --conf.host "$AWX_URL" --conf.username "$AWX_USERNAME" --conf.password "$AWX_PASSWORD" --conf.insecure \
    job_templates create \
    --name "베어메탈 서버 완전 설정" \
    --job_type run \
    --inventory "$INVENTORY_ID" \
    --project "$PROJECT_ID" \
    --playbook "playbooks/main-baremetal-setup.yml" \
    --ask_variables_on_launch true \
    --become_enabled true

# OS 설치 템플릿
awx --conf.host "$AWX_URL" --conf.username "$AWX_USERNAME" --conf.password "$AWX_PASSWORD" --conf.insecure \
    job_templates create \
    --name "OS 설치" \
    --job_type run \
    --inventory "$INVENTORY_ID" \
    --project "$PROJECT_ID" \
    --playbook "playbooks/os-install.yml" \
    --ask_variables_on_launch true \
    --become_enabled true

# 펌웨어 업그레이드 템플릿
awx --conf.host "$AWX_URL" --conf.username "$AWX_USERNAME" --conf.password "$AWX_PASSWORD" --conf.insecure \
    job_templates create \
    --name "펌웨어 업그레이드" \
    --job_type run \
    --inventory "$INVENTORY_ID" \
    --project "$PROJECT_ID" \
    --playbook "playbooks/firmware-upgrade.yml" \
    --ask_variables_on_launch true \
    --become_enabled true

# 드라이버 설치 템플릿
awx --conf.host "$AWX_URL" --conf.username "$AWX_USERNAME" --conf.password "$AWX_PASSWORD" --conf.insecure \
    job_templates create \
    --name "드라이버 설치" \
    --job_type run \
    --inventory "$INVENTORY_ID" \
    --project "$PROJECT_ID" \
    --playbook "playbooks/driver-install.yml" \
    --ask_variables_on_launch true \
    --become_enabled true

echo ""
echo "=== AWX 설정 완료 ==="
echo "AWX 웹 인터페이스에서 Job Template을 확인하고 실행할 수 있습니다."
echo "URL: $AWX_URL"
