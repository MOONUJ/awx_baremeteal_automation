#!/bin/bash
# 실행 권한: chmod +x scripts/validate_project.sh
# 베어메탈 서버 자동화 검증 스크립트

set -e

echo "=== 베어메탈 서버 자동화 프로젝트 검증 ==="

# 기본 디렉토리 확인
echo "1. 프로젝트 구조 확인..."
required_dirs=(
    "playbooks"
    "roles/os_install"
    "roles/firmware_upgrade" 
    "roles/driver_install"
    "inventories"
    "group_vars"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✓ $dir 존재"
    else
        echo "  ✗ $dir 누락"
        exit 1
    fi
done

# 필수 파일 확인
echo "2. 필수 파일 확인..."
required_files=(
    "ansible.cfg"
    "requirements.yml"
    "requirements.txt"
    "README.md"
    "playbooks/main-baremetal-setup.yml"
    "inventories/production.ini"
    "group_vars/all.yml"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file 존재"
    else
        echo "  ✗ $file 누락"
        exit 1
    fi
done

# Ansible 구문 검사
echo "3. Ansible 플레이북 구문 검사..."
for playbook in playbooks/*.yml; do
    if ansible-playbook --syntax-check "$playbook" >/dev/null 2>&1; then
        echo "  ✓ $(basename $playbook) 구문 정상"
    else
        echo "  ✗ $(basename $playbook) 구문 오류"
        ansible-playbook --syntax-check "$playbook"
        exit 1
    fi
done

# YAML 유효성 검사  
echo "4. YAML 파일 유효성 검사..."
find . -name "*.yml" -o -name "*.yaml" | while read file; do
    if python3 -c "import yaml; yaml.safe_load(open('$file'))" >/dev/null 2>&1; then
        echo "  ✓ $file YAML 형식 정상"
    else
        echo "  ✗ $file YAML 형식 오류"
        exit 1
    fi
done

# 변수 참조 확인
echo "5. 변수 참조 무결성 확인..."
if grep -r "{{ [^}]*undefined" . --include="*.yml" --include="*.yaml" >/dev/null 2>&1; then
    echo "  ✗ 정의되지 않은 변수 발견"
    grep -r "{{ [^}]*undefined" . --include="*.yml" --include="*.yaml"
    exit 1
else
    echo "  ✓ 변수 참조 정상"
fi

echo ""
echo "=== 검증 완료 ==="
echo "모든 검사가 통과했습니다. AWX에서 사용할 준비가 되었습니다."
