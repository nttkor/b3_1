# B6-1 R01 — Evidence Guide

Cloud Evidence는 문서가 아니라 **실제 AWS resource와 실제 HTTP 동작**을 증명해야 합니다.

## 1. Network

- VPC ID / CIDR
- Public Subnet ID / CIDR
- Internet Gateway attachment
- Route Table의 `0.0.0.0/0 → IGW`

## 2. EC2 / Web Server

EC2 안에서:

```bash
systemctl status nginx --no-pager
sudo nginx -t
curl -i http://localhost/
curl -i http://localhost/health
curl -I https://example.com
ss -lntp | grep ':80'
```

## 3. Security Group

필수 Evidence:

- HTTP TCP 80 ← `0.0.0.0/0`
- SSH TCP 22 ← learner current Public IP/32
- `0.0.0.0/0` 전체 포트 허용 없음

Public IP 자체를 확인할 때는 신뢰 가능한 외부 방법을 사용하되 Token/credential을 출력하지 않습니다.

## 4. External Access

공식 A/B 중 하나 이상:

- A: 외부 브라우저 `http://<PublicIP>`
- B: `curl -i http://<PublicIP>/health`

Reference는 `/health` 방식도 쉽게 검증할 수 있도록 Nginx 설정을 제공합니다.

## 5. IAM

- 사용 IAM User/Role 이름
- Attached policy 범위
- `AdministratorAccess` 없음
- 실습과 무관한 S3/RDS 권한 없음

Access Key/Secret Access Key/Session Token은 Evidence 금지입니다.

## 6. Architecture

Reference source:

- `docs/architecture.mmd`

Phase C 공식 제출물:

- `docs/architecture.png` 또는 `docs/architecture.pdf`

실제 VPC/Subnet/IGW/EC2/SG와 외부→서비스 traffic flow를 반영합니다.

## 7. Troubleshooting

`docs/troubleshooting.md`에 실제 최소 1건:

```text
Symptom → Hypothesis → Verification → Action → Result → Recurrence Prevention
```

## 8. Cleanup

`docs/cleanup-checklist.md`를 실제 완료하고 EC2/VPC/IGW/SG/EIP/EBS 등 B6-1 과금 리소스가 남지 않았는지 확인합니다.

## 9. Verify

```bash
bash training/round-01-clear/environment/verify.sh --runtime
```

이 script는 읽기 전용 describe/curl 검증만 수행합니다. IAM 상세 범위, SSH 실제 접속, localhost/outbound, cleanup은 별도 실제 확인이 필요합니다.

## CLEAR

Reference 구조나 AWS Console screenshot 한 장만으로 CLEAR하지 않습니다. Network path, Web Server 내부, External HTTP, IAM, Troubleshooting, Architecture, Cleanup이 서로 연결되어야 합니다.
