# B6-1 R01 — Evaluation Q&A Reference

## 1. VPC, Subnet, Route Table, Internet Gateway의 역할 차이는?

- **VPC**: AWS 안에서 분리한 가상 네트워크의 큰 경계입니다.
- **Subnet**: VPC CIDR을 더 작은 네트워크 단위로 나눈 영역입니다.
- **Route Table**: 목적지 CIDR별로 트래픽을 어느 target으로 보낼지 결정합니다.
- **Internet Gateway**: VPC와 Internet 사이 통신 경로를 제공하는 gateway입니다.

Public Subnet이 되려면 단순히 이름에 public이 붙는 것이 아니라 외부 통신에 필요한 route와 instance public address 조건이 함께 맞아야 합니다.

## 2. 외부 사용자가 EC2 Nginx에 도달하는 흐름은?

```text
User
→ Public IPv4
→ Internet Gateway
→ Public Route Table
→ Public Subnet
→ Security Group HTTP 80 허용
→ EC2
→ Nginx :80
```

한 단계라도 빠지면 외부 접속이 실패할 수 있습니다.

## 3. Security Group과 IAM은 무엇이 다른가?

Security Group은 **Network traffic**을 허용/차단하는 instance-level stateful firewall 역할입니다. IAM은 **AWS API에서 누가 어떤 Cloud resource 작업을 할 수 있는지** 권한을 결정합니다. HTTP 80 허용 문제를 IAM으로 해결하거나, EC2 생성 권한 문제를 Security Group으로 해결할 수는 없습니다.

## 4. 왜 HTTP 80은 `0.0.0.0/0`이고 SSH 22는 내 IP/32인가?

웹 서비스는 외부 사용자가 접근해야 하므로 HTTP는 Internet에 공개합니다. SSH는 관리용 포트이므로 필요한 관리자 source만 허용해 공격 표면을 줄입니다. `/32`는 단일 IPv4 주소만 허용하는 CIDR입니다.

## 5. SSH에 `0.0.0.0/0`을 쓰면 왜 위험한가?

Internet 전체에서 SSH login 시도를 보낼 수 있어 brute-force, credential abuse, 취약점 스캔 노출이 커집니다. B6-1에서는 learner의 현재 Public IP 또는 지정 대역으로 제한합니다.

## 6. 왜 AdministratorAccess를 사용하지 않는가?

실습에 필요하지 않은 거의 모든 AWS resource를 변경할 수 있는 권한까지 부여하면 credential 오용이나 실수의 영향 범위가 지나치게 커집니다. 최소권한 원칙은 필요한 Action/Resource/조건만 허용해 피해 범위를 줄입니다.

## 7. EC2에서 `curl localhost`는 성공하는데 외부에서 실패하면 무엇부터 보는가?

Nginx 자체는 동작한다는 의미이므로 외부 경로를 우선 봅니다.

1. EC2 Public IPv4
2. Security Group HTTP 80
3. Subnet Route Table의 `0.0.0.0/0 → IGW`
4. IGW의 VPC attachment
5. Network ACL 같은 추가 경계

즉 Application 안쪽보다 Network path를 먼저 좁힙니다.

## 8. 외부 접속도 실패하고 localhost도 실패하면?

EC2 안의 Web Server를 먼저 확인합니다.

```text
systemctl status nginx
ss -lntp | grep :80
nginx -t
journalctl / nginx log
```

Network를 바꾸기 전에 instance 내부 service가 실제 80을 listen하는지 확인합니다.

## 9. Public Subnet인데 Internet outbound가 안 되면?

`0.0.0.0/0 → Internet Gateway`, IGW attachment, Public IPv4, Security Group egress/NACL 등을 확인합니다. Public이라는 label만으로 Internet 경로가 자동 보장되는 것은 아닙니다.

## 10. 왜 Troubleshooting을 증상→가설→검증→조치 순서로 기록하는가?

가설을 확인하지 않고 설정을 여러 개 동시에 바꾸면 실제 원인을 알 수 없고 재발 방지도 어렵습니다. 증거를 바탕으로 범위를 좁혀 한 가지 원인을 검증한 뒤 필요한 변경만 해야 재현 가능하고 안전합니다.

## 11. 왜 cleanup이 미션의 일부인가?

Cloud resource는 실습 종료 후에도 실행되면 과금이 계속될 수 있습니다. EC2뿐 아니라 Elastic IP, Volume/Snapshot 같은 별도 리소스도 비용 요인이 될 수 있으므로 Evidence 확보 후 의존성을 확인하며 제거해야 합니다.

## 12. Architecture diagram에는 왜 traffic flow가 필요할까?

VPC/Subnet/EC2 상자만 그리면 실제 요청이 어디로 들어오고 어떤 보안 경계를 통과하는지 알기 어렵습니다. 외부→IGW→Route→SG→EC2/Nginx 흐름을 표시해야 설계와 장애 진단을 함께 설명할 수 있습니다.

## 13. `/health` endpoint를 두는 이유는?

복잡한 페이지 렌더링과 분리해서 Web Server가 최소한 HTTP 요청에 정상 응답하는지 빠르게 확인할 수 있습니다. B6-1 Reference는 Nginx에서 `/health`에 고정 `200 OK`/`OK`를 반환하게 합니다.

## 14. Cloud resource ID나 Public IP는 Secret인가?

일반적으로 Password/API Secret과 같은 인증 Secret은 아니지만 인프라 식별 정보이므로 Evidence에는 평가에 필요한 범위만 공개하는 것이 좋습니다. Access Key, Secret Access Key, Session Token, SSH Private Key는 절대 공개하지 않습니다.
