# 베어메탈 서버 자동화 프로젝트

이 프로젝트는 AWX를 통해 베어메탈 서버의 OS 설치, 펌웨어 업그레이드, 드라이버 설치를 자동화하는 Ansible 플레이북을 제공합니다.

## 프로젝트 구조

```
baremetal-server-automation/
├── playbooks/                 # 메인 플레이북들
│   ├── main-baremetal-setup.yml
│   ├── os-install.yml
│   ├── firmware-upgrade.yml
│   └── driver-install.yml
├── roles/                     # Ansible 역할들
│   ├── os_install/
│   ├── firmware_upgrade/
│   └── driver_install/
├── inventories/               # 인벤토리 파일들
│   └── production.ini
├── group_vars/               # 그룹별 변수
│   ├── all.yml
│   ├── dell_servers.yml
│   └── hp_servers.yml
├── host_vars/                # 호스트별 변수
├── ansible.cfg               # Ansible 설정
├── requirements.yml          # Collection 요구사항
└── requirements.txt          # Python 패키지 요구사항
```

## 지원 하드웨어

- **Dell PowerEdge**: iDRAC, OpenManage, DSU 지원
- **HP ProLiant**: iLO, Service Pack for ProLiant 지원  
- **Supermicro**: BMC, SUM 지원

## 주요 기능

### 1. OS 설치
- PXE 부트 지원
- Ubuntu, CentOS, RHEL 지원
- 킥스타트/프리시드 자동 설정
- IPMI/iDRAC를 통한 원격 설치

### 2. 펌웨어 업그레이드
- BIOS/UEFI 펌웨어 업그레이드
- BMC/iDRAC/iLO 펌웨어 업그레이드
- 네트워크 어댑터 펌웨어 업그레이드
- 안전한 롤백 기능

### 3. 드라이버 설치
- 네트워크 드라이버 (Intel, Broadcom, Mellanox)
- 스토리지 드라이버 (MegaRAID, MPT3SAS, NVMe)
- GPU 드라이버 (NVIDIA, AMD)
- 벤더별 관리 도구 설치

## AWX 설정

### 1. 프로젝트 생성
1. AWX 웹 인터페이스에서 **Projects** 메뉴로 이동
2. **+** 버튼을 클릭하여 새 프로젝트 생성
3. 다음 정보 입력:
   - **Name**: `베어메탈 서버 자동화`
   - **SCM Type**: `Git`
   - **SCM URL**: `https://github.com/your-org/baremetal-server-automation.git`
   - **SCM Branch**: `main`

### 2. 인벤토리 생성
1. **Inventories** 메뉴에서 새 인벤토리 생성
2. **Sources** 탭에서 프로젝트의 인벤토리 파일 연결

### 3. Credential 설정
다음 Credential들을 생성해야 합니다:
- **Machine Credential**: 서버 SSH 접근용
- **Vault Credential**: Ansible Vault 암호용 (IPMI 비밀번호 등)

### 4. Job Template 생성

#### 전체 설정 Job Template
- **Name**: `베어메탈 서버 완전 설정`
- **Playbook**: `playbooks/main-baremetal-setup.yml`
- **Extra Variables**:
```yaml
stage: all
reboot_after_install: true
verify_after_upgrade: true
```

#### OS 설치 Job Template  
- **Name**: `OS 설치`
- **Playbook**: `playbooks/os-install.yml`
- **Extra Variables**:
```yaml
os_type: ubuntu
os_version: "22.04"
reboot_after_install: true
```

#### 펌웨어 업그레이드 Job Template
- **Name**: `펌웨어 업그레이드`  
- **Playbook**: `playbooks/firmware-upgrade.yml`
- **Extra Variables**:
```yaml
backup_current_firmware: true
verify_after_upgrade: true
```

#### 드라이버 설치 Job Template
- **Name**: `드라이버 설치`
- **Playbook**: `playbooks/driver-install.yml`
- **Extra Variables**:
```yaml
install_network_drivers: true
install_storage_drivers: true
reboot_after_driver_install: true
```

## 사용법

### 1. 변수 설정
`group_vars/all.yml`에서 환경에 맞는 변수들을 설정:
```yaml
pxe_server: "192.168.1.100"
firmware_server: "192.168.1.100"  
driver_server: "192.168.1.100"
```

### 2. 인벤토리 업데이트
`inventories/production.ini`에서 서버 정보 설정:
```ini
server01 ansible_host=192.168.1.101 ipmi_host=192.168.1.201
```

### 3. AWX에서 Job 실행
1. 해당 Job Template 선택
2. **Launch** 버튼 클릭
3. 필요시 추가 변수 설정
4. 실행 결과 모니터링

## 보안 고려사항

### 1. 민감 정보 관리
- IPMI 비밀번호는 Ansible Vault로 암호화
- SSH 키는 AWX Credential로 관리
- 펌웨어/드라이버 파일은 안전한 저장소에 보관

### 2. 네트워크 보안
- PXE/TFTP 서버는 관리 네트워크에서만 접근 가능
- IPMI 네트워크는 별도 VLAN으로 분리
- AWX 서버와 관리 대상 서버 간 방화벽 규칙 설정

## 모니터링 및 로깅

### 1. 로그 위치
- Ansible 로그: `/var/log/ansible.log`
- 개별 작업 로그: `/var/log/baremetal-setup/`
- 펌웨어 업그레이드 로그: `/var/log/firmware-upgrade.log`

### 2. 알림 설정
- Slack 웹훅을 통한 작업 완료 알림
- 이메일 알림 설정 가능
- AWX 대시보드에서 실시간 모니터링

## 문제 해결

### 1. 일반적인 문제들
- **IPMI 연결 실패**: IPMI 네트워크 연결 및 인증 정보 확인
- **PXE 부팅 실패**: TFTP 서버 및 부트 파일 확인
- **펌웨어 업그레이드 실패**: 호환성 및 전원 상태 확인
- **드라이버 컴파일 오류**: 커널 헤더 및 개발 도구 설치 확인

### 2. 로그 확인 방법
```bash
# Ansible 실행 로그
tail -f /var/log/ansible.log

# 특정 서버 설정 로그
tail -f /var/log/baremetal-setup/setup-server01-*.log

# AWX Job 로그는 웹 인터페이스에서 확인
```

## 개발 및 기여

### 1. 로컬 테스트
```bash
# 구문 검사
ansible-playbook --syntax-check playbooks/main-baremetal-setup.yml

# 드라이런 실행
ansible-playbook playbooks/main-baremetal-setup.yml --check --diff

# 특정 태그만 실행
ansible-playbook playbooks/main-baremetal-setup.yml --tags firmware_upgrade
```

### 2. 새로운 하드웨어 지원 추가
1. `roles/firmware_upgrade/tasks/` 디렉토리에 새 벤더 파일 추가
2. `group_vars/` 디렉토리에 벤더별 변수 파일 생성
3. `inventories/production.ini`에 새 서버 그룹 추가

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 연락처

- 관리자: admin@company.com
- 이슈 리포트: GitHub Issues
- 문서: 내부 위키
