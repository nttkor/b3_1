# AWS VPC EC2 배포 공식 평가 체크리스트 (`EVAL_aws_vpc_ec2_deploy.md`)

본 체크리스트는 공식 배포 실습 평가 점검 기준에 따라 전 항목의 이행 여부(`[x]`)와 근거 및 실증 데이터를 정리한 문서입니다. 각 항목별 상세 기술 설명과 심층 Q&A는 **[docs/EVAL_QA.md](EVAL_QA.md)**를 참조하십시오.

---

## 1. 기능 동작 검증

* [x] **VPC, Public Subnet, Internet Gateway, Route Table(0.0.0.0/0 → IGW)이 구성되어 있는가?**
  - **근거 및 식별자**: VPC `vpc-023d852a3471ef158` (10.0.0.0/16), 서브넷 `subnet-01c319e79337bc3b0` (10.0.1.0/24), IGW `igw-0216170a9e1876f6f`, RT `rtb-05896b293836ba38e`
  - **입증 자료**: [README.md - 배포 당시 구성](../README.md#배포-당시-구성), [docs/architecture.md](architecture.md), [describe-route-tables CLI 스냅샷](EVAL_QA.md#q1-1-vpc-public-subnet-internet-gateway-route-table00000--igw이-구성되어-있는가)
  - **콘솔 증빙**: [05-vpc-resource-map.jpg](../screenshots/05-vpc-resource-map.jpg), [18-public-route.jpg](../screenshots/18-public-route.jpg), [19-igw-attached.jpg](../screenshots/19-igw-attached.jpg)

* [x] **EC2에 SSH로 접속 가능하며, 웹 서버가 실행 중인가?**
  - **근거 및 식별자**: 인스턴스 `i-05d106a3c3409edd4` (t3.micro, Ubuntu 22.04 LTS), 공인 IP `54.180.237.44`
  - **입증 자료**: SSH 세션 로그인 성공, `cloud-init status: done`, `systemctl is-active nginx: active`, 로컬 `curl http://localhost/health: 200 OK`
  - **콘솔 증빙**: [10-ssh-connect-settings.jpg](../screenshots/10-ssh-connect-settings.jpg), [11-ssh-connected.jpg](../screenshots/11-ssh-connected.jpg), [12-instance-verification.jpg](../screenshots/12-instance-verification.jpg)

* [x] **보안 그룹 인바운드가 “필요 포트만” 허용하며, SSH(22)가 특정 IP로 제한되어 있는가?**
  - **근거 및 규칙**: `sg-06a53efc080f4c3c6` — HTTP(80) `0.0.0.0/0`, SSH(22) `121.135.181.35/32` (단일 관리자 IP 한정)
  - **입증 자료**: `0.0.0.0/0` 전체 포트(0-65535) 개방 룰 부재, 서브넷 NACL 상태 명시 ([architecture.md - NACL](architecture.md#3-서브넷-network-aclnacl-구성-및-보안-이력))
  - **콘솔 증빙**: [17-security-rules.jpg](../screenshots/17-security-rules.jpg), [22-security-sources.jpg](../screenshots/22-security-sources.jpg)

* [x] **외부 접속이 아래 방식 중 1개로 검증되는가? (제출자가 선택한 방식으로 확인)**
  * **선택 방식**: **방식 (B)** `GET http://<퍼블릭IP>/health` 호출 검증 (방식 A 브라우저 화면 동시 확보)
  * **검증 결과**: `http://54.180.237.44/health` → `HTTP/1.1 200 OK`, 평문 본문 `OK` 정상 수신
  * **입증 자료**: [README.md - 외부 접속 검증](../README.md#외부-접속-검증-방식-b-및-방식-a-병행), [external-health.txt](../evidence/external-health.txt)
  * **콘솔 증빙**: [13-external-web.jpg](../screenshots/13-external-web.jpg)

* [x] **리소스 정리 체크리스트에서 최소 5종(EC2/EBS/EIP/IGW/VPC) 정리 완료를 확인할 수 있는가?**
  - **근거**: 의존성 역순 정리 10단계 매뉴얼 및 CLI 반환 JSON 출력 완료
  - **입증 자료**: [docs/cleanup-checklist.md](cleanup-checklist.md)
  - **콘솔 증빙**: [23-ec2-termination-request.jpg](../screenshots/23-ec2-termination-request.jpg), [24-ec2-terminated.jpg](../screenshots/24-ec2-terminated.jpg), [25-ebs-deleted.jpg](../screenshots/25-ebs-deleted.jpg), [28-vpc-deleted.jpg](../screenshots/28-vpc-deleted.jpg), [30-igw-deleted.jpg](../screenshots/30-igw-deleted.jpg), [31-eip-none.jpg](../screenshots/31-eip-none.jpg)

---

## 2. 구현 구조 설명

* [x] **“외부 → IGW → Subnet → EC2”로 이어지는 네트워크 흐름을 다이어그램 기준으로 설명할 수 있는가?**
  - **다이어그램 자료**: 공식 아키텍처 이미지 [`docs/architecture.png`](architecture.png), Mermaid 토폴로지 및 시퀀스 다이어그램 ([docs/architecture.md](architecture.md))
  - **상세 설명**: [docs/EVAL_QA.md Q2-1](EVAL_QA.md#q2-1-외부--igw--subnet--ec2로-이어지는-네트워크-흐름을-다이어그램-기준으로-설명할-수-있는가)

* [x] **보안 그룹 규칙을 어떤 기준으로 최소화했는지(허용/미허용 포트) 설명할 수 있는가?**
  - **최소화 기준**: 기본 거부(Default Deny), HTTP 80 공개, 관리용 SSH 22 단일 IP(/32) 한정, 미사용 HTTPS 443 및 DB 포트 차단
  - **상세 설명**: [docs/EVAL_QA.md Q2-2](EVAL_QA.md#q2-2-보안-그룹-규칙을-어떤-기준으로-최소화했는지허용미허용-포트-설명할-수-있는가)

* [x] **외부 접속 검증을 A 또는 B 중 무엇으로 선택했고, 그 선택을 위해 무엇을 어떻게 구성했는지 설명할 수 있는가?**
  - **선택 및 구성**: 방식 B 채택 이유(표준 헬스체크 및 CI/CD 무인 자동화), User-Data 스크립트([scripts/user-data.sh](../scripts/user-data.sh))의 `return 200 'OK'` Nginx 엔드포인트 설정
  - **ALB 연동 구현 노트**: Target Group 헬스체크 연동 매개변수 CLI 수록
  - **상세 설명**: [docs/EVAL_QA.md Q2-3](EVAL_QA.md#q2-3-외부-접속-검증을-a-또는-b-중-무엇으로-선택했고-그-선택을-위해-무엇을-어떻게-구성했는지-설명할-수-있는가)

* [x] **실습 리소스를 추적/정리하기 위해 어떤 기준(태그, 이름 규칙, 체크리스트)을 사용했는지 설명할 수 있는가?**
  - **3중 추적 체계**: 태깅(`Project=codyssey-b6-1`), 이름 접두사(`b6-`), 독립 체크리스트 문서
  - **CLI 스냅샷**: `describe-tags` CLI 테이블 출력 및 [15-instance-details.jpg](../screenshots/15-instance-details.jpg)
  - **상세 설명**: [docs/EVAL_QA.md Q2-4](EVAL_QA.md#q2-4-실습-리소스를-추적정리하기-위해-어떤-기준태그-이름-규칙-체크리스트을-사용했는지-설명할-수-있는가)

---

## 3. 핵심 개념 이해

* [x] **Public Subnet Route Table의 기본 경로(0.0.0.0/0 → IGW)가 필요한 이유를 설명할 수 있는가?**
  - **핵심 원리**: Longest Prefix Match 우선순위, 외부 인터넷을 향한 기본 게이트웨이 지정, Public Subnet의 기술적 정의
  - **실증 테스트**: 기본 경로 제거 시 `Connection timed out` 발생 및 복구 시 `200 OK` 회복 로그 ([troubleshooting.md 건 4](troubleshooting.md#건-4-라우팅-변경-시나리오-테스트--기본-라우트00000--igw-제거-및-복구-시-서비스-영향))
  - **상세 설명**: [docs/EVAL_QA.md Q3-1](EVAL_QA.md#q3-1-public-subnet-route-table의-기본-경로00000--igw가-필요한-이유를-설명할-수-있는가)

* [x] **Security Group과 IAM의 책임 범위 차이를 설명하고, “최소 권한”이 왜 필요한지 설명할 수 있는가?**
  - **차이점**: 데이터 평면(IP/Port 패킷) vs 제어 평면(API 호출 권한), 인스턴스 ENI vs Identity
  - **최소 권한 예시**: 침해 반경(Blast Radius) 격리, 특정 VPC/인스턴스 ARN으로 한정한 JSON 정책 코드 제시
  - **상세 설명**: [docs/EVAL_QA.md Q3-2](EVAL_QA.md#q3-2-security-group과-iam의-책임-범위-차이를-설명하고-최소-권한이-왜-필요한지-설명할-수-있는가)

* [x] **SSH(22) 또는 DB 포트를 `0.0.0.0/0`로 열면 안 되는 이유와 대안을 설명할 수 있는가?**
  - **위험성**: 무차별 대입 공격 및 사설망 내부 횡적 이동(Lateral Movement) 위험
  - **최적 대안**: 포트 22를 완전히 닫는 AWS Systems Manager (SSM) Session Manager 3단계 구축 절차 제시
  - **상세 설명**: [docs/EVAL_QA.md Q3-3](EVAL_QA.md#q3-3-ssh22-또는-db-포트를-00000로-열면-안-되는-이유와-대안을-설명할-수-있는가)

* [x] **트러블슈팅에서 “가설 → 검증” 순서를 유지한 이유와, 로그/근거를 어떻게 활용했는지 설명할 수 있는가?**
  - **접근 방식**: 추측 기반 조치(Shotgun Debugging) 방지, 계층별 문제 분리
  - **실제 활용 로그**: `describe-instance-types` JSON, `/var/log/cloud-init-output.log`, `nginx/error.log`, CloudTrail `AccessDenied` JSON 이벤트
  - **상세 설명**: [docs/EVAL_QA.md Q3-4](EVAL_QA.md#q3-4-트러블슈팅에서-가설--검증-순서를-유지한-이유와-로그근거를-어떻게-활용했는지-설명할-수-있는가)

---

## 4. 확장 사고 및 트러블슈팅

* [x] **외부 접속이 안 될 때, 어떤 순서로(라우팅 → SG → 퍼블릭 IP/DNS → 서버 프로세스/로그) 점검하는지 설명할 수 있는가?**
  - **4단계 점검 체계**: 1. 라우팅(IGW/RT) → 2. 방화벽(SG/NACL) → 3. 주소(Public IP/DNS) → 4. 호스트(Nginx/로그)
  - **네트워크 레벨 도구**: VPC Flow Logs 분석 포맷 및 `tcpdump -i eth0 port 80` 패킷 캡처 실무 예시 수록
  - **상세 설명**: [docs/EVAL_QA.md Q4-1](EVAL_QA.md#q4-1-외부-접속이-안-될-때-어떤-순서로라우팅--sg--퍼블릭-ipdns--서버-프로세스로그-점검하는지-설명할-수-있는가)

* [x] **IAM 권한이 부족해 작업이 실패했다면, “권한을 무작정 올리지 않고” 어떤 방식으로 필요한 최소 범위를 찾아갈지 설명할 수 있는가?**
  - **디버깅 절차**: CLI 에러 메시지 분석 → CloudTrail 이벤트 조회 → Policy Simulator 테스트 → 단일 액션 점진 추가
  - **거버넌스 체계**: 자동화된 5단계 IAM 변경 리뷰/승인 체크리스트 테이블 수록
  - **상세 설명**: [docs/EVAL_QA.md Q4-2](EVAL_QA.md#q4-2-iam-권한이-부족해-작업이-실패했다면-권한을-무작정-올리지-않고-어떤-방식으로-필요한-최소-범위를-찾아갈지-설명할-수-있는가)

* [x] **트래픽이 늘어 “인스턴스를 2대로 늘려야” 한다면, 현재 구조에서 무엇이 병목이며 어떤 구성요소(ALB 등)를 추가할지 설명할 수 있는가?**
  - **병목 분석**: 단일 인스턴스 SPOF, 단일 가용영역 취약성, 단일 IP 결합
  - **확장 아키텍처**: Multi-AZ ALB 도입, Private Subnet 이동, SG Chaining, Auto Scaling Group 연동
  - **상세 설명**: [docs/EVAL_QA.md Q4-3](EVAL_QA.md#q4-3-트래픽이-늘어-인스턴스를-2대로-늘려야-한다면-현재-구조에서-무엇이-병목이며-어떤-구성요소alb-등를-추가할지-설명할-수-있는가)

* [x] **Billing에 예상치 못한 비용이 찍혔다면, 어떤 리소스부터 의심하고 어떻게 추적/정리할지 설명할 수 있는가?**
  - **우선 의심 자원**: NAT Gateway, 미연결 Elastic IP, 고아 EBS 볼륨, 규격 초과 인스턴스
  - **FinOps 도구**: Cost Explorer CLI 일별 사용량 쿼리, AWS Budgets $1.00 예산 알람 JSON
  - **콘솔 증빙**: [billing-october-2026.png](../screenshots/user-provided/billing-october-2026.png), [credits-120.png](../screenshots/user-provided/credits-120.png)
  - **상세 설명**: [docs/EVAL_QA.md Q4-4](EVAL_QA.md#q4-4-billing에-예상치-못한-비용이-찍혔다면-어떤-리소스부터-의심하고-어떻게-추적정리할지-설명할-수-있는가)
