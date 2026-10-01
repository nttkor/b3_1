# B6-1 R01 — Reference Build

## 목적

공식 Mission/Evaluation을 기준으로 **AWS VPC 안의 Public Subnet에 EC2 + Nginx를 배포하고, 필요한 포트만 여는 최소권한 웹 서비스 인프라**의 Reference Complete Path를 준비합니다.

Phase A에서는 실제 AWS 리소스를 생성하지 않습니다. VPC/EC2/Security Group/IAM/Public IP/과금 리소스는 Phase C Runtime에서 사용자가 직접 생성·검증·정리합니다. 실제 Cloud 결과가 없는데 PASS/CLEAR로 기록하지 않습니다.

## Source of Truth

1. `b6-1-mission.pdf`
2. `b6-1-mission.md`
3. `b6-1-evaluation.md`

## Reference Golden Path

- Cloud: AWS
- Region: **`ap-northeast-2` (Seoul, 공식 필수)**
- VPC CIDR 예시: `10.10.0.0/16`
- Public Subnet CIDR 예시: `10.10.1.0/24`
- Internet Gateway 1개
- Public Route: `0.0.0.0/0 → Internet Gateway`
- Public Route Table을 Public Subnet에 association
- EC2: Ubuntu LTS 계열 1대, Public Subnet 배치
- Public IPv4: 외부 접속에 필요
- Security Group:
  - TCP 80 ← `0.0.0.0/0`
  - TCP 22 ← **본인의 현재 Public IP/32만**
  - 전체 포트 `0.0.0.0/0` 허용 금지
- Web Server: Nginx
- `/health` → HTTP 200 + `OK`
- IAM: 실습에 필요한 EC2/VPC/Security Group 범위만, `AdministratorAccess` 금지
- Secret/credential/SSH Private Key는 GitHub·채팅·Evidence에 저장하지 않음

## Reference Complete Path

1. AWS Account/Region/IAM/Billing 안전 확인
2. VPC 생성
3. Public Subnet 생성
4. Internet Gateway 생성 및 VPC 연결
5. Route Table에 `0.0.0.0/0 → IGW`
6. Route Table을 Public Subnet에 association
7. Security Group 최소 포트 구성
8. EC2 생성 / Public IPv4 확인
9. SSH 접속
10. Nginx 설치/실행
11. instance localhost HTTP 200
12. instance outbound Internet 확인
13. 외부 브라우저 또는 `/health` HTTP 200
14. Architecture PNG/PDF 작성
15. Troubleshooting 실제 1건 이상 기록
16. IAM 최소권한 재검토
17. Evidence 연결
18. Cleanup 후 과금 리소스 없음 확인
19. Evaluation 설명
20. CLEAR

## 준비된 Reference

- `reference/nginx/default.conf`
- `reference/iam/least-privilege.md`
- `docs/architecture.mmd`
- `docs/troubleshooting.md`
- `docs/cleanup-checklist.md`
- `docs/requirements-mapping.md`
- `docs/evaluation-qa.md`
- `environment/verify.sh`
- `evidence/README.md`
- 상세 `BEGINNER-GUIDE.md`
- 상세 `CHECKLIST.md`
- `REFERENCE-STATUS.md`

## Runtime Verification 설계

`verify.sh --runtime`은 AWS 리소스를 변경하지 않고 읽기 전용으로 다음을 확인하도록 설계했습니다.

- Region = `ap-northeast-2`
- VPC/Subnet/IGW/Route
- Route Table ↔ Public Subnet association
- SG HTTP 80 / SSH 22 learner CIDR
- all-traffic public rule 부재
- EC2 running / Subnet / SG / Public IPv4
- 외부 `/health` 응답
- Runtime Evidence 파일
- Architecture PNG/PDF
- Troubleshooting/Cleanup의 실제 완료 여부

## 현재 판정

**Reference Build: CORE READY**  
**Runtime Mission: ⬜ NOT STARTED**

실제 AWS Runtime 결과와 Cleanup을 확인하기 전에는 `✅ CLEAR`로 변경하지 않습니다.
