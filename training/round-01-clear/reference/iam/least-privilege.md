# B6-1 IAM Least-Privilege Reference

> Phase A에서는 실제 IAM 사용자/Role/Policy를 생성하지 않습니다. Runtime에서 사용하는 AWS 계정 구조와 리소스 범위에 맞춰 최소권한을 구성합니다.

## 공식 목표

- 실습에 사용하는 IAM 사용자 또는 Role 1개
- EC2/VPC/Security Group 구성에 필요한 범위만 허용
- 실습과 무관한 S3/RDS 등 권한은 부여하지 않음
- `AdministratorAccess` 금지

## 필요한 작업 범주

실제 선택한 Console/CLI 흐름에 따라 다음 범주 중 필요한 것만 허용합니다.

### VPC / Network

- VPC 생성/조회/태그
- Subnet 생성/조회/태그
- Internet Gateway 생성/연결/조회/태그
- Route Table 생성/조회/연결/Route 생성
- Security Group 생성/조회/Rule 관리/태그

### EC2

- AMI/Instance Type/Key Pair 등 실행에 필요한 조회
- EC2 Instance 생성/조회/태그/중지/종료
- Public IP 및 Network Interface 관련 조회

## 최소권한 검토 질문

1. 이 Action이 B6-1 수행에 실제 필요한가?
2. Resource ARN을 더 좁힐 수 있는가?
3. Region/Tag 조건으로 범위를 줄일 수 있는가?
4. 실습과 무관한 서비스 권한이 섞여 있지 않은가?
5. `AdministratorAccess` 또는 광범위한 `Action: "*"`가 없는가?

## Runtime Evidence

실제 Policy 전체 Secret을 저장하는 것이 아니라 다음을 증빙합니다.

- 사용 IAM principal 이름/Role 이름
- AdministratorAccess 미부여
- B6-1에 필요한 서비스 범위만 포함
- 실습과 무관한 S3/RDS 등 권한 없음

Access Key/Secret Access Key/Session Token은 채팅·GitHub·Evidence에 기록하지 않습니다.
