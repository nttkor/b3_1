# B6-1 R01 — Reference Status

## 판정

**Reference Build: CORE READY**  
**Runtime Mission 상태: ⬜ NOT STARTED**

실제 AWS 리소스, SSH, Nginx, 외부 HTTP, IAM, Cleanup Evidence가 없으므로 Runtime CLEAR는 아닙니다.

## 공식 Source

- `b6-1-mission.pdf`
- `b6-1-mission.md`
- `b6-1-evaluation.md`

## CORE READY 근거

- Seoul Region `ap-northeast-2` Golden Path
- VPC / Public Subnet / IGW / Public Route / SG / EC2 architecture
- HTTP 80 public / SSH 22 learner CIDR-only rule
- Nginx port 80 + `/health` 200 OK Reference
- IAM least-privilege guide
- Troubleshooting Runtime template
- Cleanup checklist
- Requirement Mapping / Evaluation Q&A / Evidence Guide
- detailed Beginner Guide / Checklist
- read-only AWS Runtime verifier

## 자체감사 보강

- Runtime verifier에 Region 고정 검사 추가
- Route Table이 Public Subnet에 실제 association 되었는지 검사
- SSH 22가 `B6_SSH_CIDR`로 제한되고 `0.0.0.0/0`가 아닌지 검사
- EC2가 지정 Public Subnet/SG에 실제 연결됐는지 검사
- external `/health` 실제 응답 검사
- Runtime Evidence 6종 gate 추가
- 공식 architecture PNG/PDF 존재 gate 추가
- Troubleshooting/Cleanup의 `TODO_RUNTIME`이 남아 있으면 Runtime 실패
- Reference와 실제 AWS 결과를 엄격히 분리

## Phase C에서만 PASS할 항목

- 실제 VPC/Subnet/IGW/Route/SG/EC2
- 실제 SSH
- Nginx/local HTTP/outbound Internet
- 실제 external HTTP
- IAM 최소권한 실제 확인
- architecture PNG/PDF
- 실제 troubleshooting
- 실제 cleanup
- Runtime Evidence
- Evaluation 설명

## Gate

- [x] Source/Evaluation 매핑
- [x] 최소 충분 Reference 설계
- [x] Security/IAM 원칙
- [x] Runtime read-only verification 설계
- [x] Cleanup/Evidence plan
- [x] 허위 Runtime PASS 없음
- [x] BLOCKER/MAJOR Reference 결함 없음

따라서 Phase A 기준 **CORE READY**입니다.
