# B6-1 Round 01 — Mission Clear Checklist

Reference 준비 상태와 실제 AWS Runtime 상태를 분리합니다.

## A. Source / Scope
- [x] Mission PDF/MD 확인
- [x] Evaluation 확인
- [x] 서울 Region 요구 반영
- [x] Root 계정 금지 / IAM User 또는 Role 원칙 반영
- [x] 필수와 Bonus(HTTPS/Docker) 분리

## B. Reference Architecture
- [x] VPC
- [x] Public Subnet
- [x] Internet Gateway
- [x] Public Route Table
- [x] `0.0.0.0/0 → IGW`
- [x] Security Group
- [x] EC2 / Nginx
- [x] External → Service traffic flow
- [x] outbound Internet 흐름

## C. Security / IAM Reference
- [x] HTTP 80 ← `0.0.0.0/0`
- [x] SSH 22 ← `MY_IP/32`
- [x] all traffic ← `0.0.0.0/0` 금지
- [x] AdministratorAccess 금지
- [x] 실습 무관 S3/RDS 권한 제외 원칙
- [x] Access Key/Secret/Session Token Evidence 금지

## D. Web Reference
- [x] Nginx port 80
- [x] `/health` endpoint
- [x] `/health` returns 200 + `OK`
- [x] localhost verification path
- [x] external `/health` verification path

## E. Documentation
- [x] Architecture Mermaid source
- [x] Troubleshooting runtime template
- [x] Cleanup checklist
- [x] Requirement → Implementation → Verification → Evidence mapping
- [x] Evaluation Q&A
- [x] Evidence Guide
- [x] Detailed Beginner Guide

## F. Verification Design
- [x] Reference file/static checks
- [x] AWS CLI read-only Runtime verify
- [x] Region = `ap-northeast-2`
- [x] VPC existence
- [x] Subnet→VPC
- [x] IGW→VPC attachment
- [x] `0.0.0.0/0 → IGW`
- [x] Route Table→Public Subnet association
- [x] SG HTTP 80 public
- [x] SG SSH 22 learner CIDR only
- [x] all-traffic public rule rejection
- [x] EC2 running / subnet / SG / Public IP
- [x] external `/health` check
- [x] Runtime Evidence file gate
- [x] Architecture PNG/PDF gate
- [x] Troubleshooting TODO gate
- [x] Cleanup TODO gate

## G. Phase C AWS Runtime — 아직 PASS 아님
- [ ] IAM User/Role로 로그인
- [ ] `ap-northeast-2`
- [ ] VPC 1개 실제 생성
- [ ] Public Subnet 1개 실제 생성
- [ ] IGW 실제 attach
- [ ] Public Route Table 실제 association
- [ ] `0.0.0.0/0 → IGW` 실제 확인
- [ ] EC2 실제 실행
- [ ] Public IPv4 실제 확인
- [ ] SSH 실제 성공
- [ ] Nginx 실제 running
- [ ] `nginx -t` 실제 성공
- [ ] localhost HTTP 200
- [ ] EC2 outbound Internet 성공
- [ ] SG HTTP 80 공개
- [ ] SG SSH 22 learner IP/32 제한
- [ ] AdministratorAccess 없음
- [ ] 무관 서비스 권한 없음
- [ ] 외부 `/health` 200 + OK

## H. 공식 제출물 / Evidence — 아직 PASS 아님
- [ ] `docs/architecture.png` 또는 `.pdf`
- [ ] README에 방식 A/B + 실제 URL/IP
- [ ] 외부 접속 screenshot/output
- [ ] `docs/troubleshooting.md` 실제 사례 1+
- [ ] `docs/cleanup-checklist.md` 실제 완료
- [ ] EC2 / EBS / EIP / IGW / VPC 정리 확인
- [ ] `evidence/runtime/aws-network.txt`
- [ ] `evidence/runtime/server.txt`
- [ ] `evidence/runtime/ssh.txt`
- [ ] `evidence/runtime/iam.md`
- [ ] `evidence/runtime/external.txt`
- [ ] `evidence/runtime/evaluation.md`
- [ ] `verify.sh --runtime` 실제 0 FAIL

## I. Evaluation Explanation — 실제 수행 후
- [ ] external→IGW→Subnet→EC2 흐름 설명
- [ ] SG 최소화 기준 설명
- [ ] 방식 A/B 선택 이유 설명
- [ ] tagging/name/cleanup 추적 방식 설명
- [ ] `0.0.0.0/0 → IGW` 이유 설명
- [ ] SG vs IAM 설명
- [ ] SSH/DB public-open 위험 설명
- [ ] 가설→검증 troubleshooting 설명
- [ ] 접속 장애 점검 순서 설명
- [ ] IAM 권한부족 대응 설명
- [ ] 2-instance/ALB 확장 설명
- [ ] 예상외 Billing 추적 설명

## J. Final CLEAR
- [x] Phase A Reference 핵심 준비
- [x] Reference/Runtime 분리
- [x] 허위 Runtime PASS 없음
- [ ] 실제 AWS Runtime 완료
- [ ] 실제 Cleanup 완료
- [ ] 실제 Evidence 완료
- [ ] 평가 설명 완료
- [ ] **✅ MISSION CLEAR**

현재 판정: **Reference CORE READY / Runtime ⬜ NOT STARTED**
