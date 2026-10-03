# 스크립트 및 정책 디렉터리 가이드 (`scripts/README.md`)

본 디렉터리는 **B3-1 (AWS 웹 서비스 인프라 구축)** 미션에서 인프라 자동화 및 보안 권한 제어를 위해 사용하는 스크립트와 정책 문서를 포함합니다.

---

## 1. 파일 구성 및 개요

```text
/Users/mpeg46551/b3_1/scripts/
├── README.md           # [본 문서] scripts 디렉터리 파일 개요, 상세 주석 및 권한 해설서
├── iam-policy.json     # 실습 전용 IAM 사용자를 위한 최소권한 인라인 정책 정의 (JSON)
└── user-data.sh        # EC2 인스턴스 초기 부팅 시 Nginx 자동 설치 및 헬스체크 구성 쉘 스크립트
```

| 파일명 | 실행/적용 주체 | 권한 수준 | 역할 요약 |
|---|---|---|---|
| [scripts/iam-policy.json](file:///Users/mpeg46551/b3_1/scripts/iam-policy.json) | AWS IAM 서비스 (루트 계정 또는 관리자가 유저에 부착) | 인라인 정책 (B6LabMinimumPrivilege) | 실습에 필수적인 EC2, VPC, SG 등의 작업만 선별 허용하고 타 서비스(S3, RDS 등) 차단 |
| [scripts/user-data.sh](file:///Users/mpeg46551/b3_1/scripts/user-data.sh) | EC2 인스턴스 내부 cloud-init 데몬 | `root` (게스트 OS 최고관리자) | 최초 부팅 시 Nginx 자동 설치, `/health` 200 OK 엔드포인트 설정 및 데몬 활성화 |

---

## 2. [scripts/user-data.sh](file:///Users/mpeg46551/b3_1/scripts/user-data.sh) 상세 해설

### 2.1 동작 메커니즘
- **실행 시점**: EC2 인스턴스가 프로비저닝된 직후 게스트 OS의 부팅 과정(cloud-init 초기화 단계)에서 **단 1회** 실행됩니다.
- **실행 권한**: `root` 슈퍼유저 권한으로 실행되므로 `sudo` 명령어가 불필요합니다.
- **로그 확인**: 모든 표준 출력(stdout) 및 표준 오류(stderr)는 인스턴스 내부의 `/var/log/cloud-init-output.log`에 저장됩니다.

### 2.2 코드 블록별 상세 주석

```bash
#!/bin/bash
# 스크립트 에러 발생 시 즉시 중단 (잘못된 상태 전파 방지)
set -e

# [1단계: 패키지 업데이트 및 Nginx 설치]
# 최신 패키지 인덱스를 동기화하고 Nginx 웹 서버를 비대화형(-y)으로 무인 설치합니다.
apt-get update -y
apt-get install -y nginx

# [2단계: Nginx 기본 사이트 설정 파일 작성]
# /health 엔드포인트와 루트(/) 경로에 대한 응답을 정의합니다.
cat > /etc/nginx/sites-available/default << 'NGINXCONF'
server {
    listen 80 default_server;       # IPv4 포트 80 수신
    listen [::]:80 default_server;   # IPv6 포트 80 수신

    # 외부 접속 검증 (방식 B) 및 로드밸런서용 헬스체크 엔드포인트
    location /health {
        add_header Content-Type text/plain;
        return 200 'OK';            # HTTP 200 코드와 문자열 'OK' 즉시 반환
    }

    # 기본 루트 경로 환영 페이지 (방식 A)
    location / {
        add_header Content-Type text/html;
        return 200 '<html><body><h1>Hello Cloud &mdash; b6-1</h1><p>codyssey-b6-1 | Jack B.</p></body></html>';
    }
}
NGINXCONF

# [3단계: 문법 검증 및 서비스 활성화]
nginx -t                    # Nginx 설정 파일 문법 검사
systemctl restart nginx     # 새 설정 적용을 위해 Nginx 재시작
systemctl enable nginx      # 서버 재부팅 시에도 자동 기동되도록 systemd에 등록
```

---

## 3. [scripts/iam-policy.json](file:///Users/mpeg46551/b3_1/scripts/iam-policy.json) 상세 해설 및 주석

> [!NOTE]
> **JSON 파일 내 주석 안내**  
> 표준 JSON 규격(RFC 8259) 및 AWS IAM 정책 엔진은 `//` 또는 `#` 형태의 인라인 주석을 지원하지 않으며, 주석 문자가 포함될 경우 `aws iam put-user-policy` 실행 시 `MalformedPolicyDocument: Invalid JSON` 오류가 발생합니다. 따라서 실제 `iam-policy.json` 파일은 표준 JSON 형식을 유지하고, 각 권한 항목별 상세 주석 및 해설은 본 문서에서 제공합니다.

### 3.1 정책 설계 원칙: 최소 권한의 원칙 (Least Privilege)
- **관리자 권한(`AdministratorAccess`) 배제**: 전체 AWS 자원에 무제한 접근할 수 있는 권한을 주지 않습니다.
- **불필요한 서비스 원천 차단**: S3, RDS, Lambda, Bedrock, DynamoDB 등 본 실습과 무관한 모든 서비스는 묵시적 거부(Implicit Deny) 처리됩니다.
- **자격증명 유출 피해 격리 (Blast Radius Minimization)**: 만약 본 실습용 IAM 키가 유출되더라도, 타 리소스에 접근하거나 관리자 권한을 획득할 수 없습니다.

### 3.2 허용된 49개 액션(Action)별 상세 주석 및 필요성

#### (1) VPC 및 서브넷 관리 (9개)
```json
"ec2:CreateVpc",             // VPC 생성 (10.0.0.0/16 격리 네트워크 생성)
"ec2:DeleteVpc",             // 실습 종료 후 VPC 삭제
"ec2:DescribeVpcs",          // VPC 상태 및 속성 조회
"ec2:ModifyVpcAttribute",    // VPC의 DNS 호스트 이름 활성화 (enableDnsHostnames)
"ec2:DescribeVpcAttribute",  // VPC DNS 속성 설정 상태 확인
"ec2:CreateSubnet",          // Public Subnet (10.0.1.0/24) 생성
"ec2:DeleteSubnet",          // 실습 종료 후 서브넷 삭제
"ec2:DescribeSubnets",       // 서브넷 상태 및 CIDR 블록 조회
"ec2:ModifySubnetAttribute"  // 서브넷 내 인스턴스에 퍼블릭 IP 자동 할당 활성화 (MapPublicIpOnLaunch)
```

#### (2) 인터넷 게이트웨이(IGW) 관리 (5개)
```json
"ec2:CreateInternetGateway",   // VPC 외부 인터넷 통신을 위한 IGW 생성
"ec2:DeleteInternetGateway",   // 실습 종료 후 IGW 삭제
"ec2:DescribeInternetGateways",// IGW 목록 및 상태 조회
"ec2:AttachInternetGateway",   // 생성된 IGW를 VPC에 연결
"ec2:DetachInternetGateway"    // 실습 종료 시 VPC에서 IGW 분리 (삭제 선행 작업)
```

#### (3) 라우팅 테이블(Route Table) 관리 (7개)
```json
"ec2:CreateRouteTable",        // Public Subnet 전용 커스텀 라우트 테이블 생성
"ec2:DeleteRouteTable",        // 실습 종료 후 라우트 테이블 삭제
"ec2:DescribeRouteTables",     // 라우트 테이블 및 라우팅 경로 조회
"ec2:CreateRoute",             // 기본 경로 (0.0.0.0/0 -> IGW) 추가
"ec2:DeleteRoute",             // 기본 경로 삭제
"ec2:AssociateRouteTable",     // 라우트 테이블을 Public Subnet에 명시적 연결
"ec2:DisassociateRouteTable"   // 실습 종료 시 라우트 테이블과 서브넷 연결 해제
```

#### (4) 보안 그룹(Security Group) 관리 (7개)
```json
"ec2:CreateSecurityGroup",         // 인스턴스 방화벽인 보안 그룹 생성
"ec2:DeleteSecurityGroup",         // 실습 종료 후 보안 그룹 삭제
"ec2:DescribeSecurityGroups",      // 보안 그룹 규칙 및 ID 조회
"ec2:AuthorizeSecurityGroupIngress", // 인바운드 규칙 추가 (HTTP 80 전세계, SSH 22 내 IP)
"ec2:RevokeSecurityGroupIngress",    // 인바운드 규칙 제거
"ec2:AuthorizeSecurityGroupEgress",  // 아웃바운드 규칙 추가 (패키지 다운로드용)
"ec2:RevokeSecurityGroupEgress"     // 아웃바운드 규칙 제거
```

#### (5) 키페어(Key Pair) 관리 (3개)
```json
"ec2:CreateKeyPair",   // SSH 접속을 위한 신규 키페어 생성 (.pem 파일 발급)
"ec2:DeleteKeyPair",   // 실습 종료 후 키페어 삭제
"ec2:DescribeKeyPairs" // 계정에 등록된 키페어 목록 조회
```

#### (6) EC2 인스턴스 라이프사이클 관리 (8개)
```json
"ec2:RunInstances",           // EC2 가상 머신 생성 및 실행 (User-Data 주입)
"ec2:TerminateInstances",     // 실습 종료 후 인스턴스 영구 종료(삭제)
"ec2:DescribeInstances",      // 인스턴스 상태(running/terminated) 및 공인 IP 조회
"ec2:DescribeInstanceStatus", // 인스턴스 상태 검사(System/Instance Status Check 2/2) 확인
"ec2:StopInstances",          // 인스턴스 일시 정지
"ec2:StartInstances",         // 인스턴스 재시작
"ec2:DescribeImages",         // Ubuntu 22.04 최신 AMI ID 검색 및 유효성 확인
"ec2:DescribeAvailabilityZones" // 서울 리전 내 가용영역 (ap-northeast-2a 등) 확인
```

#### (7) 메타데이터 및 태그 관리 (4개)
```json
"ec2:DescribeInstanceTypes",     // 프리티어 대상 인스턴스 타입 확인 (free-tier-eligible 필터링)
"ec2:DescribeNetworkInterfaces", // 인스턴스에 부착된 ENI 상세 정보 조회
"ec2:CreateTags",                // 리소스 추적을 위한 Project 태그 부여 (Project=codyssey-b6-1)
"ec2:DescribeTags"               // 태그 기준으로 실습 리소스 일괄 조회
```

#### (8) Elastic IP (고정 공인 IP) 관리 (5개)
```json
"ec2:AllocateAddress",    // 고정 퍼블릭 IP(EIP) 할당 (필요 시)
"ec2:ReleaseAddress",     // 미사용 EIP 반환 (유휴 비용 발생 방지)
"ec2:AssociateAddress",   // EIP를 인스턴스 ENI에 연결
"ec2:DisassociateAddress",// EIP 연결 해제
"ec2:DescribeAddresses"   // 계정에 할당된 EIP 목록 및 연결 상태 조회
```

#### (9) EBS 스토리지 볼륨 관리 (2개)
```json
"ec2:DescribeVolumes", // 인스턴스 종료 후 미사용(available) 볼륨 잔여 여부 확인
"ec2:DeleteVolume"     // 미사용 EBS 볼륨 수동 영구 삭제 (과금 원천 차단)
```

---

## 4. 적용 및 실행 방법

### IAM 사용자에게 정책 적용하기 (루트 계정 또는 관리자 실행)
```bash
aws iam put-user-policy \
  --user-name codyssey-b6-user \
  --policy-name B6LabMinimumPrivilege \
  --policy-document file://scripts/iam-policy.json
```

### EC2 인스턴스 생성 시 User Data 전달하기 (b6user 프로파일 실행)
```bash
aws ec2 run-instances \
  --image-id resolve:ssm:/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp3/ami-id \
  --instance-type t3.micro \
  --key-name b6-keypair \
  --security-group-ids <SG_ID> \
  --subnet-id <SUBNET_ID> \
  --user-data file://scripts/user-data.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=b6-web-ec2},{Key=Project,Value=codyssey-b6-1}]' \
  --profile b6user --region ap-northeast-2
```
