# Codyssey Basic B6-1 — Cloud Deployment

## 현재 훈련 상태

- 구분: **필수 미션 (REQUIRED)**
- Round: **R01 — CLEAR**
- Runtime Mission 상태: **⬜ NOT STARTED**
- Reference Build: **CORE READY**

공식 Mission/Evaluation을 기준으로 AWS 네트워크·EC2·Nginx·Security Group·IAM·Troubleshooting·Cleanup Reference 기준본을 준비했습니다. 실제 AWS Runtime/Evidence 전에는 `✅ CLEAR`가 아닙니다.

## 공식 원본

- `b6-1-mission.pdf`
- `b6-1-mission.md`
- `b6-1-evaluation.md`

공식 원본은 수정하지 않습니다.

## 시작 위치

- `training/round-01-clear/BEGINNER-GUIDE.md`
- `training/round-01-clear/REFERENCE-STATUS.md`
- `training/round-01-clear/CHECKLIST.md`

## Reference 핵심

- Region: `ap-northeast-2`
- VPC / Public Subnet / IGW / Public Route Table
- EC2 + Public IPv4
- SG: HTTP 80 public, SSH 22 learner IP/32 only
- Nginx `/health` → 200 `OK`
- IAM least privilege
- Architecture source / Troubleshooting template / Cleanup checklist
- read-only `verify.sh --runtime`

## Runtime에서 반드시 채울 항목

- External validation 방식 A 또는 B와 실제 URL/IP
- `docs/architecture.png` 또는 `.pdf`
- 실제 `docs/troubleshooting.md`
- 실제 `docs/cleanup-checklist.md`
- AWS/Server/SSH/IAM/External/Evaluation Evidence

## CLEAR 원칙

Cloud Reference 문서나 AWS Console screenshot 한 장만으로 CLEAR하지 않습니다. 실제 Network path, Security Group, EC2/SSH, Nginx 내부 동작, 외부 HTTP, IAM 최소권한, Architecture, Troubleshooting, Cleanup을 모두 확인한 뒤 `✅ CLEAR`로 변경합니다.
