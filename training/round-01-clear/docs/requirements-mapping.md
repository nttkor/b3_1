# B6-1 R01 — Requirement / Implementation / Verification / Evidence

| ID | Requirement | Reference Preparation | Runtime Verification | Evidence |
|---|---|---|---|---|
| R01 | VPC 1개 | Golden Path/architecture | AWS describe/Console | VPC ID/CIDR |
| R02 | Public Subnet 1개 | `10.10.1.0/24` example | subnet→VPC / public IP setting | subnet details |
| R03 | Internet Gateway | architecture/runbook | IGW attachment | IGW details |
| R04 | `0.0.0.0/0 → IGW` | architecture | Route Table check | route details |
| R05 | instance outbound Internet | Runtime guide | EC2 `curl https://example.com` | terminal |
| R06 | EC2 in Public Subnet | Golden Path | instance subnet/public IP | EC2 details |
| R07 | SSH access | SG/IAM/env guide | actual SSH from learner IP | terminal |
| R08 | Nginx installed/running | `reference/nginx/default.conf` | `systemctl`, `nginx -t` | terminal |
| R09 | localhost HTTP 200 | Nginx config | `curl -i localhost` | HTTP output |
| R10 | HTTP 80 from 0.0.0.0/0 | SG rule design | AWS describe | SG Evidence |
| R11 | SSH 22 learner IP only | SG rule design | AWS describe + current IP | SG Evidence |
| R12 | no all-port 0.0.0.0/0 | safety rule | AWS describe | SG Evidence |
| R13 | IAM User/Role 1 | least-privilege guide | attached policy review | IAM Evidence |
| R14 | no AdministratorAccess | least-privilege guide | IAM policy review | IAM Evidence |
| R15 | no unrelated S3/RDS permission | least-privilege guide | IAM policy review | IAM Evidence |
| R16 | external HTTP validation A/B | `/health` config + runbook | browser/curl external | screenshot/output |
| R17 | Architecture PNG/PDF | `architecture.mmd` source | render final actual topology | `docs/architecture.png|pdf` |
| R18 | Troubleshooting 1+ | runtime template | real symptom→prevention | report |
| R19 | Cleanup checklist | checklist prepared | actual delete/terminate | completed checklist |
| R20 | README execution/deployment info | root/Beginner Guide | document review | README |
| R21 | Cloud concepts explanation | `evaluation-qa.md` | user explanation | evaluator check |

## 중요한 구분

`architecture.mmd`는 Reference source이며 공식 제출 artifact인 PNG/PDF를 대신하지 않습니다. Phase C에서 실제 Region/CIDR/resource label과 최종 traffic flow를 반영해 PNG/PDF로 만들어야 합니다.

## Runtime Gate

Cloud는 실제 존재/접속/과금 정리까지 확인해야 합니다. `verify.sh` Reference mode PASS만으로 VPC/EC2/SG/IAM/외부 접속을 PASS로 처리하지 않습니다.
