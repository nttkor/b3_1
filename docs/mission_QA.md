# B3-1 미션 요구사항 심층 Q&A 가이드 (`mission_QA.md`)

본 문서는 원본 미션 명세서([docs/b3_1mission.md](b3_1mission.md))의 **전체 요구사항(미션 소개, 4대 최종 결과물, 5대 과제 목표, 6대 기능 요구사항, 제약사항, 보너스 과제)**을 완벽히 분석하여, 평가자와 학습자가 주고받을 수 있는 모든 실전 질문과 모범 답변을 정리한 심층 가이드입니다.

본 프로젝트의 실제 구축 자원 데이터([README.md](file:///Users/mpeg46551/b3_1/README.md), [docs/architecture.md](file:///Users/mpeg46551/b3_1/docs/architecture.md), [scripts/](file:///Users/mpeg46551/b3_1/scripts/))를 바탕으로 작성되었습니다.

---

## 📌 목차

1. [제1장: 미션 개요 및 핵심 설계 철학 (Mission Philosophy)](#제1장-미션-개요-및-핵심-설계-철학)
2. [제2장: 과제 5대 학습 목표 완벽 구술 답변 (Core Learning Objectives)](#제2장-과제-5대-학습-목표-완벽-구술-답변)
3. [제3장: 6대 기능 요구사항 구현 및 검증 Q&A (Functional Requirements)](#제3장-6대-기능-요구사항-구현-및-검증-qa)
4. [제4장: 최종 4대 결과물 규격 및 검증 기준 (Deliverables Specifications)](#제4장-최종-4대-결과물-규격-및-검증-기준)
5. [제5장: 제약 사항 준수 및 보너스 과제 Q&A (Constraints & Bonus Tasks)](#제5장-제약-사항-준수-및-보너스-과제-qa)
6. [제6장: 실전 트러블슈팅 및 인프라 아키텍처 심화 면접 대비 (Deep-Dive)](#제6장-실전-트러블슈팅-및-인프라-아키텍처-심화-면접-대비)

---

## 제1장: 미션 개요 및 핵심 설계 철학

### Q1. 미션 소개에서 "일단 서버에 올렸는데 외부에서 안 들어와요"라는 증상이 발생하는 근본적인 기술적 원인 4가지는 무엇인가?
**답변:**
서버 내부에 애플리케이션(Nginx)이 실행 중이더라도 외부 패킷이 도달하지 못하는 원인은 클라우드 계층별로 4가지가 있습니다:
1. **인터넷 관문 및 라우팅 부재 (L3 네트워크)**: 서브넷의 라우트 테이블(Route Table)에 기본 경로(`0.0.0.0/0 → IGW`)가 없거나 Internet Gateway가 VPC에 Attach되지 않은 경우.
2. **공인 주소(Public IP) 부재 (L3 IP 주소)**: EC2 인스턴스에 인터넷에서 라우팅 가능한 공인 IPv4 주소가 할당되지 않은 경우.
3. **보안 그룹(Security Group) 인바운드 차단 (가상 방화벽)**: 보안 그룹 인바운드 규칙에 클라이언트의 IP 대역과 HTTP 포트(TCP 80)가 허용되어 있지 않은 경우.
4. **OS 내부 방화벽 및 프로세스 바인딩 (L7 호스트)**: Ubuntu 내부의 `ufw` 방화벽이 80 포트를 막고 있거나, Nginx가 `0.0.0.0:80`이 아닌 `127.0.0.1:80`에만 바인딩된 경우.

### Q2. 클라우드를 "그냥 빠른 컴퓨터"가 아니라 "네트워크, 보안, IAM이 묶인 환경"으로 보아야 하는 이유는 무엇인가?
**답변:**
온프레미스 단일 컴퓨터와 달리, AWS 클라우드는 **Shared Responsibility Model(공동 책임 모델)**과 **API 제어 평면(Control Plane)** 기반으로 동작합니다:
* 컴퓨팅(EC2)은 반드시 격리된 가상 네트워크(VPC)와 서브넷 안에서만 존재할 수 있습니다.
* 모든 네트워크 패킷은 보안 그룹(Security Group)과 라우트 테이블의 엄격한 규칙 검사를 통과해야만 서버에 도달합니다.
* 인프라를 생성하고 조작하는 주체는 IAM 자격증명과 최소권한 정책에 의해 엄격히 통제됩니다.
* 만약 보안 그룹 포트를 전체 개방(`0.0.0.0/0`)하거나 루트 계정/`AdministratorAccess` 키를 방치하면, 단 하나의 열린 포트나 유출된 키로 인해 서버가 탈취(크립토재킹)되어 수천만 원의 과금 폭탄으로 이어지는 치명적인 사고가 발생하기 때문입니다.

---

## 제2장: 과제 5대 학습 목표 완벽 구술 답변

### Q3. [목표 1] VPC, Subnet, Route Table, Internet Gateway가 각각 어떤 역할을 하며 트래픽 흐름이 어떻게 이어지는지 설명하라.
**답변:**
* **각 구성요소의 역할**:
  * **VPC (`10.0.0.0/16`)**: 다른 AWS 고객과 완전히 분리된 전용 가상 사설 네트워크 공간입니다.
  * **Public Subnet (`10.0.1.0/24`)**: VPC 내부를 가용 영역(`ap-northeast-2a`) 단위로 나눈 네트워크 블록으로, 인터넷과 직접 통신할 수 있는 영역입니다.
  * **Internet Gateway (IGW)**: VPC와 공용 인터넷 사이에서 1:1 양방향 NAT 주소 변환을 수행하고 패킷을 중계하는 수평 확장 관문입니다.
  * **Route Table**: 서브넷 내부에서 발생한 패킷이 어디로 가야 하는지 알려주는 이정표로, `0.0.0.0/0` 목적지를 IGW로 라우팅합니다.
* **외부 트래픽의 상세 이동 흐름**:
  1. 외부 클라이언트가 브라우저나 curl로 `http://54.180.237.44:80` 요청을 전송합니다.
  2. 패킷이 AWS 백본을 거쳐 VPC 경계의 **Internet Gateway (`igw-0216170a9e1876f6f`)**에 도착합니다.
  3. IGW는 목적지 공인 IP(`54.180.237.44`)를 EC2의 사설 IP(`10.0.1.120`)로 1:1 NAT 변환합니다.
  4. VPC 라우터는 **Route Table (`rtb-05896b293836ba38e`)**을 확인하여 패킷을 **Public Subnet (`subnet-01c319e79337bc3b0`)**으로 전달합니다.
  5. 패킷이 EC2의 가상 네트워크 인터페이스(ENI) 직전에 위치한 **Security Group (`sg-06a53efc080f4c3c6`)**에 도달하여 TCP 80 허용 여부를 검사받습니다.
  6. 검사를 통과한 패킷이 **EC2 (`i-05d106a3c3409edd4`)** 내부의 Nginx 웹 서버에 도달하고, 헬스체크 응답(`200 OK`)이 역순으로 클라이언트에 반환됩니다.

### Q4. [목표 2] Security Group과 IAM의 역할 차이를 구분하고, 최소 권한 원칙(Least Privilege)을 왜/어떻게 적용하는지 설명하라.
**답변:**
* **Security Group vs IAM 차이**:
  * **Security Group**: **데이터 평면(Data Plane)의 네트워크 방화벽**입니다. 인스턴스로 들어오고 나가는 실제 네트워크 패킷(IP, 프로토콜, 포트 번호)을 제어하며, 허용 규칙만 작성하는 상태 저장(Stateful) 방식입니다.
  * **IAM (Identity and Access Management)**: **제어 평면(Control Plane)의 접근 제어 시스템**입니다. "누가(User/Role)" "어떤 AWS 자원(Resource)"에 "어떤 조작(Action: ec2:RunInstances 등)"을 수행할 수 있는지를 JSON 정책으로 인가(Authorization)합니다.
* **최소 권한 원칙의 적용 이유와 방법**:
  * **이유**: 자격증명 탈취나 관리자 실수 발생 시 피해 반경(Blast Radius)을 최소화하기 위함입니다.
  * **적용 방법**: 루트 계정 사용을 배제하고 실습 전용 유저(`codyssey-b6-user`)를 생성한 뒤, `AdministratorAccess` 대신 EC2/VPC 실습에 반드시 필요한 49개 액션만 명시적으로 허용한 인라인 정책([scripts/iam-policy.json](file:///Users/mpeg46551/b3_1/scripts/iam-policy.json))을 화이트리스트 방식으로 부여했습니다.

### Q5. [목표 3] 외부 요청이 EC2의 웹 서버까지 도달하기 위해 필요한 3대 설정을 논리적으로 설명하라.
**답변:**
외부 트래픽이 웹 서버에 닿으려면 아래 3가지 설정이 **단 하나도 빠짐없이 모두 충족**되어야 합니다:
1. **라우팅 경로 (Routing Path)**: 서브넷과 연결된 Route Table에 기본 인터넷 경로(`0.0.0.0/0 → IGW`)가 등록되어 있어야 합니다. (경로가 없으면 외부 통신 불가)
2. **공인 주소 (Public Reachability)**: EC2 인스턴스에 인터넷에서 접근 가능한 공인 IPv4 주소가 바인딩되어 있어야 합니다. (`MapPublicIpOnLaunch=true`를 통한 자동 할당)
3. **가상 방화벽 개방 (Security Group Inbound)**: EC2 인스턴스에 연결된 보안 그룹의 인바운드 규칙에 클라이언트 IP(`0.0.0.0/0`) 및 웹 포트(`TCP 80`)가 허용되어 있어야 합니다.

### Q6. [목표 4] 오류 발생 시 로그/증상을 근거로 원인을 가설화하고 검증 후 조치하는 트러블슈팅 과정을 설명하라.
**답변:**
직관이나 임의 수정이 아닌, **`증상 → 가설 → 검증 → 조치 → 결과 → 재발방지`**의 6단계 과학적 방법론을 적용했습니다:
* **실사례 1 (인스턴스 생성 에러)**:
  * *증상*: `aws ec2 run-instances --instance-type t2.micro` 실행 시 `InvalidParameterCombination` 발생.
  * *가설*: 해당 계정/서울 리전에서 `t2.micro`가 프리티어 대상이 아닐 것이다.
  * *검증*: `aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true"`로 프리티어 목록 조회 $\to$ `t3.micro` 확인.
  * *조치 및 결과*: `--instance-type t3.micro`로 변경하여 인스턴스 정상 생성 성공.
* **실사례 2 (초기 헬스체크 무응답)**:
  * *증상*: EC2가 `running` 직후 `curl /health` 접속 실패.
  * *가설*: 하이퍼바이저 기동 상태와 OS 부팅 및 cloud-init의 Nginx 설치 완료 시점 간에 시차(Time lag)가 존재할 것이다.
  * *검증 및 조치*: `aws ec2 wait instance-status-ok` 및 시스템 초기화 대기(75초) 후 재호출 $\to$ `200 OK` 정상 수신.

### Q7. [목표 5] 클라우드 과금이 발생하는 대표 요인을 알고, 실습 리소스를 안전하게 역순으로 정리하는 이유를 설명하라.
**답변:**
* **대표 과금 요인**:
  1. 실행 중인 EC2 인스턴스 시간당 컴퓨트 비용.
  2. EC2에 연결되지 않은 채 방치된 미사용 Elastic IP (시간당 $0.005).
  3. EC2 인스턴스 종료 후 삭제되지 않고 남아있는 고아(Orphan) EBS 볼륨 스토리지 요금.
  4. 시간당 고정 요금이 큰 자원 (NAT Gateway 시간당 ~$0.059, ALB 시간당 ~$0.022).
  5. 2024년 이후 도입된 공인 IPv4 주소 사용료 (시간당 $0.005).
* **생성의 역순으로 삭제해야 하는 이유**:
  AWS 인프라 자원은 상호 간에 강한 참조 무결성(Referential Integrity) 의존성을 갖습니다:
  * EC2가 실행 중이면 보안 그룹과 서브넷을 삭제할 수 없습니다.
  * 서브넷과 ENI가 남아있으면 VPC를 삭제할 수 없습니다.
  * IGW가 VPC에 Attach되어 있으면 IGW를 삭제할 수 없습니다.
  따라서 `EC2 인스턴스(EBS 포함) → Key Pair → Security Group → Subnet/Route Table → Internet Gateway → VPC → IAM` 순서로 생성의 역순으로 삭제해야만 `DependencyViolation` 에러 없이 깨끗하게 제거됩니다.

---

## 제3장: 6대 기능 요구사항 구현 및 검증 Q&A

### Q8. [기능 1-1] VPC(10.0.0.0/16)와 Public Subnet(10.0.1.0/24)을 어떻게 설계했으며 서브넷에서 실제 사용 가능한 IP 개수는 몇 개인가?
**답변:**
* **설계**: VPC는 대규모 확장이 가능한 사설 IP 사설망 대역(`10.0.0.0/16`, 총 65,536개 주소)으로 생성했고, 그 안에서 웹 서버 배포를 위해 서울 리전 `ap-northeast-2a`에 `10.0.1.0/24`(총 256개 주소)의 퍼블릭 서브넷을 구성했습니다.
* **사용 가능한 IP 개수**: **251개**입니다.
* **이유**: AWS는 모든 서브넷에서 내부 관리용으로 5개의 IP 주소를 예약합니다:
  * `10.0.1.0`: 네트워크 주소
  * `10.0.1.1`: VPC 라우터 주소
  * `10.0.1.2`: DNS 서버 주소 (AmazonProvidedDNS)
  * `10.0.1.3`: AWS 향후 사용 예약 주소
  * `10.0.1.255`: 네트워크 브로드캐스트 주소 (VPC 미지원이나 예약됨)

### Q9. [기능 1-2] Public Subnet의 아웃바운드 인터넷 통신은 어떻게 검증했는가?
**답변:**
두 가지 방식으로 검증을 완료했습니다:
1. **인스턴스 내부 curl 요청**:
   ```bash
   $ curl -I https://example.com
   HTTP/2 200
   content-type: text/html
   ```
2. **user-data 스크립트 실행 성공**: EC2 최초 부팅 시 [scripts/user-data.sh](file:///Users/mpeg46551/b3_1/scripts/user-data.sh)에서 `apt-get update -y` 및 `apt-get install -y nginx`를 실행하여 외부 Ubuntu 공식 패키지 미러 서버로부터 정상적으로 패키지를 다운로드했습니다.

### Q10. [기능 2] EC2 컴퓨트 인스턴스 배포 및 SSH 접속, 웹 서버 구동은 어떻게 검증했는가?
**답변:**
1. **EC2 배포**: 서울 리전 프리티어 규격인 `t3.micro` 인스턴스(`i-05d106a3c3409edd4`)를 Ubuntu 22.04 LTS 최신 AMI 기반으로 실행했습니다.
2. **SSH 원격 접속**: 로컬에 다운로드한 `b6-keypair.pem`의 파일 권한을 `chmod 400`으로 제한한 뒤, 허용된 개인 공인 IP에서 SSH 접속을 성공했습니다:
   ```bash
   $ ssh -i b6-keypair.pem ubuntu@54.180.237.44
   Welcome to Ubuntu 22.04.4 LTS ...
   ubuntu@ip-10-0-1-120:~$
   ```
3. **Nginx 데몬 상태**: `systemctl is-active nginx` 결과 `active` 확인 및 `sudo nginx -t` 구문 검사 성공을 확인했습니다.
4. **로컬 HTTP 요청**: 인스턴스 내부에서 `curl http://localhost` 호출 시 `200 OK`와 환영 HTML 응답(`Hello Cloud — b6-1`)을 수신했습니다.

### Q11. [기능 3] 보안 그룹 규칙에서 왜 SSH(22)는 개인 IP로 제한하고, 전체 포트(0-65535) 개방은 금지하는가?
**답변:**
* **SSH(22) 개인 IP 제한 이유**: 포트 22를 `0.0.0.0/0`으로 전체 개방하면 인터넷의 수많은 악성 봇넷이 24시간 무차별 대입 공격(Brute-force)과 SSH 사전 공격을 가합니다. 이를 방어하기 위해 관리자의 현재 공인 IP(`121.135.181.35/32`) 단일 IP에서만 통신할 수 있도록 최소화했습니다.
* **0-65535 포트 전체 개방 금지 이유**: 웹 서버 운영에 필요한 포트는 HTTP(80)뿐입니다. 사용하지 않는 포트(예: 데이터베이스 포트 3306, 관리 포트 등)까지 모두 열어두면 OS나 서비스의 보안 취약점을 통한 원격 코드 실행(RCE) 침해사고의 통로가 되기 때문입니다.

### Q12. [기능 4] IAM 최소권한 원칙에서 관리자 권한(AdministratorAccess)을 주지 않고 어떻게 정책을 설계했는가?
**답변:**
* 루트 계정은 일체 사용하지 않고 실습 전용 IAM 유저 `codyssey-b6-user`를 생성했습니다.
* `AdministratorAccess`나 `ec2:*` 와일드카드 권한을 부여하지 않고, 실습에 반드시 필요한 49개 액션만 화이트리스트로 지정한 인라인 정책 `B6LabMinimumPrivilege`([scripts/iam-policy.json](file:///Users/mpeg46551/b3_1/scripts/iam-policy.json))을 작성했습니다.
* 허용 액션은 EC2 실행/종료(`RunInstances`, `TerminateInstances`), VPC/서브넷 관리(`CreateVpc`, `CreateSubnet`), 보안 그룹 설정(`AuthorizeSecurityGroupIngress`), 키페어 생성(`CreateKeyPair`) 등으로 한정했으며, 실습과 무관한 S3, RDS, Lambda 등은 일체 차단했습니다.

### Q13. [기능 5] 외부 접속 검증에서 방식 A(브라우저)와 방식 B(GET /health) 중 무엇을 선택했고 왜 선택했는가?
**답변:**
* **선택 방식**: **방식 B (`GET http://<퍼블릭IP>/health`)**를 채택했습니다.
* **검증 결과**:
  ```bash
  $ curl -i http://54.180.237.44/health
  HTTP/1.1 200 OK
  Content-Type: text/plain
  OK
  ```
* **선택 이유**:
  브라우저 접속(방식 A)은 사람이 시각적으로 확인하기에는 좋으나, 자동화 스크립트나 CI/CD 파이프라인, 그리고 향후 인프라를 확장하여 로드밸런서(ALB)를 도입할 때 대상 그룹(Target Group)의 상태 검사 엔드포인트로 활용하기에는 평문과 명확한 HTTP 200 상태 코드를 반환하는 `/health` API 엔드포인트(방식 B)가 업계 표준에 부합하기 때문입니다.

### Q14. [기능 6] 운영 안정성을 위해 실습 종료 후 정리 완료를 확인한 5대 핵심 자원은 무엇인가?
**답변:**
[docs/cleanup-checklist.md](file:///Users/mpeg46551/b3_1/docs/cleanup-checklist.md)에 따라 아래 5대 자원의 삭제를 완벽히 확인했습니다:
1. **EC2 인스턴스**: `i-05d106a3c3409edd4` $\to$ `terminated` 상태 전환 확인.
2. **EBS 볼륨**: 인스턴스 종료 시 루트 볼륨 자동 삭제 및 `describe-volumes`에서 잔여 볼륨 없음 확인.
3. **Elastic IP**: 고정 IP 미할당 확인 (과금 방지를 위해 자동 배정 퍼블릭 IP 사용).
4. **Internet Gateway**: `igw-0216170a9e1876f6f` VPC Detach 및 삭제 확인.
5. **VPC & Subnet**: 라우트 테이블 연결 해제 후 서브넷 및 VPC `vpc-023d852a3471ef158` 삭제 확인.

---

## 제4장: 최종 4대 결과물 규격 및 검증 기준

### Q15. [결과물 1] 아키텍처 다이어그램 규격과 포함된 핵심 요소는 무엇인가?
**답변:**
* **제출 규격**: [docs/architecture.md](file:///Users/mpeg46551/b3_1/docs/architecture.md) 및 [README.md](file:///Users/mpeg46551/b3_1/README.md)에 Mermaid 다이어그램으로 수록.
* **포함된 핵심 요소**:
  * VPC 경계 (`10.0.0.0/16`)
  * Public Subnet (`10.0.1.0/24`, `ap-northeast-2a`)
  * Internet Gateway (`igw-0216170a9e1876f6f`)
  * Route Table (`0.0.0.0/0 → IGW`)
  * Security Group (`HTTP: 80`, `SSH: 22`)
  * EC2 인스턴스 (`t3.micro`, Nginx, 공인 IP: `54.180.237.44`)
  * 외부 인터넷에서 웹 서버로 이어지는 단계별 트래픽 흐름

### Q16. [결과물 2] 웹 서비스 외부 접속 증빙 규격은 어떻게 충족되었는가?
**답변:**
* **제출 규격**: [README.md](file:///Users/mpeg46551/b3_1/README.md) 제4.5절 및 6절에 선택 방식과 접속 정보, curl 실행 로그 및 응답 헤더 기재.
* **충족 내용**:
  * 선택 방식: **방식 B (`GET /health`)**
  * 접속 URL: `http://54.180.237.44/health`
  * 응답 상태: `HTTP/1.1 200 OK`
  * 응답 본문: `OK`
  * 상태 코드 검증: `curl -o /dev/null -s -w "%{http_code}\n" ...` $\to$ `200` 수신

### Q17. [결과물 3] 트러블슈팅 보고서의 최소 규격과 수록된 3건의 실사례는 무엇인가?
**답변:**
* **제출 규격**: [docs/troubleshooting.md](file:///Users/mpeg46551/b3_1/docs/troubleshooting.md)에 `증상 → 가설 → 검증 → 조치 → 결과 → 재발방지` 6단계 표준 템플릿으로 작성.
* **수록된 3건의 실사례**:
  1. `t2.micro` 프리티어 파라미터 에러 $\to$ 서울 리전 프리티어 지원 목록 확인 후 `t3.micro`로 교체.
  2. EC2 기동 직후 헬스체크 연결 지연 $\to$ cloud-init 부팅 대기 및 `instance-status-ok` 확인 후 정상 수신.
  3. 루트 계정 SSO 인증과 실습 IAM 유저 프로파일 경합 $\to$ `--profile b6user` 명시적 분리로 최소권한 격리.

### Q18. [결과물 4] 리소스 정리 체크리스트는 어떤 형식으로 작성되었는가?
**답변:**
* **제출 규격**: [docs/cleanup-checklist.md](file:///Users/mpeg46551/b3_1/docs/cleanup-checklist.md)에 의존성 역순 10단계 매뉴얼 수록.
* **충족 내용**:
  * 자원별 식별자(ID) 사전 정리 테이블 제공
  * 각 단계별 즉시 실행 가능한 AWS CLI 명령어 수록
  * 인스턴스 상태 대기(`aws ec2 wait instance-terminated`), 미사용 볼륨 확인 쿼리, Billing 대시보드 최종 확인 지침 포함

---

## 제5장: 제약 사항 준수 및 보너스 과제 Q&A

### Q19. [제약사항 1] 서울 리전(ap-northeast-2)과 프리티어(Free Tier) 범위 준수를 어떻게 보장했는가?
**답변:**
1. **리전 고정**: 모든 AWS CLI 명령어에 `--region ap-northeast-2`를 지정하여 서울 리전 단일 배포를 준수했습니다.
2. **컴퓨팅**: `t3.micro` 인스턴스 1대만 사용하여 월 750시간 무료 한도 내에서 운영했습니다.
3. **스토리지**: EBS 볼륨 크기를 8 GiB(gp3)로 설정하여 프리티어 월 30 GiB 무료 한도 내에서 시작했습니다.
4. **유휴 과금 차단**: 고정 비용이 나가는 Elastic IP를 할당하지 않고 EC2 시작 시 자동 부여되는 동적 퍼블릭 IP를 사용했습니다.

### Q20. [보너스 1] HTTPS를 적용하려면 본 아키텍처에서 무엇을 추가로 구현해야 하는가?
**답변:**
보너스 1 과제를 수행하기 위해서는 다음 4단계 작업이 추가로 필요합니다:
1. **도메인 연결**: Freenom/내 도메인 한국 등에서 도메인을 발급받고, Route 53 또는 DNS 공급자에서 EC2 퍼블릭 IP(`54.180.237.44`)로 `A 레코드`를 등록합니다.
2. **보안 그룹 인바운드 수정**: 보안 그룹에 HTTPS 기본 포트인 **TCP 443**을 `0.0.0.0/0`으로 허용하는 인바운드 규칙을 추가합니다.
3. **SSL/TLS 인증서 발급**: EC2 내부에서 `certbot`을 설치하고 Let's Encrypt를 통해 무료 인증서를 자동 발급받습니다 (`sudo certbot --nginx -d example.com`).
4. **웹 서버 HTTPS 리다이렉트**: Nginx 가상호스트 설정에 443 SSL 블록을 추가하고, 포트 80(HTTP) 요청은 자동으로 443(HTTPS)으로 301 영구 리다이렉트되도록 구성합니다.

### Q21. [보너스 2] Docker 컨테이너로 웹 서비스를 배포하려면 어떤 변경이 필요한가?
**답변:**
보너스 2 과제를 수행하기 위한 작업 흐름은 다음과 같습니다:
1. **Docker 엔진 설치**: EC2 인스턴스에 Docker를 설치하고 사용자를 docker 그룹에 추가합니다 (`sudo apt install docker.io -y`).
2. **호스트 Nginx 중지**: 호스트 OS에서 실행 중인 Nginx 서비스가 80 포트를 점유하고 있으므로 중지합니다 (`sudo systemctl stop nginx && sudo systemctl disable nginx`).
3. **컨테이너 실행 및 포트 바인딩**:
   ```bash
   docker run -d --name my-web -p 80:80 nginx:alpine
   ```
4. **검증**:
   * 로컬 검증: `docker ps` 상태 Up 확인 및 `curl http://localhost` 200 검증.
   * 외부 검증: 외부에서 `http://54.180.237.44` 접속 시 Nginx 환영 페이지 확인.

---

## 제6장: 실전 트러블슈팅 및 인프라 아키텍처 심화 면접 대비

### Q22. 외부에서 curl 요청 시 무한 대기(Connection Timeout)가 발생할 때와 즉시 거부(Connection Refused)가 발생할 때의 원인 차이는 무엇인가?
**답변:**
* **Connection Timeout (시간 초과)**:
  * **원인**: 패킷이 중간 네트워크 방화벽에서 조용히 버려졌을 때(Drop) 발생합니다.
  * **의심 위치**: **Security Group 인바운드 규칙 미허용** 또는 **VPC Route Table에 IGW 라우팅 누락**. 클라이언트에게 거부 패킷(RST)조차 돌아오지 못하고 타임아웃이 발생합니다.
* **Connection Refused (연결 거부)**:
  * **원인**: 패킷이 EC2 인스턴스의 OS까지는 정상적으로 도달했으나, 해당 포트를 수신 대기(Listen)하는 프로세스가 없을 때 발생합니다.
  * **의심 위치**: **Nginx 웹 서버 프로세스 사망**, 아직 기동되지 않은 상태, 또는 잘못된 포트 바인딩. OS 네트워크 스택이 즉시 TCP RST 패킷을 클라이언트에 돌려줍니다.

### Q23. 인스턴스가 재부팅되었을 때 퍼블릭 IP가 바뀌지 않게 하려면 어떻게 해야 하며, 이때 발생할 수 있는 FinOps 과금 위험은 무엇인가?
**답변:**
* **해결책**: AWS의 고정 공인 IP 서비스인 **Elastic IP (EIP, 탄력적 IP)**를 할당받아 EC2 인스턴스에 연결(Associate)하면 인스턴스를 재부팅하거나 중지 후 시작해도 IP 주소가 고정됩니다.
* **FinOps 과금 위험**:
  * AWS는 자원의 낭비를 막기 위해 **실행 중인 인스턴스에 1개 연결된 EIP는 무료**로 제공하지만, **인스턴스에 연결하지 않고 방치하거나 인스턴스가 중지(Stopped)된 상태의 EIP에는 시간당 $0.005의 유휴 요금을 부과**합니다.
  * 실습 종료 시 EC2만 종료하고 EIP를 해제(Release)하지 않으면 지속적인 과금이 발생하므로 반드시 정리해야 합니다.

### Q24. 향후 사용자가 늘어나 웹 서버를 2대 이상으로 확장(Scale-out)할 때, 보안 그룹과 네트워크 구성은 어떻게 변경되어야 하는가?
**답변:**
1. **Public Subnet 다중화**: 가용성(High Availability)을 위해 서로 다른 가용영역(`ap-northeast-2a`, `ap-northeast-2c`)에 Public Subnet을 최소 2개 구성합니다.
2. **Application Load Balancer (ALB) 도입**: Public Subnet에 ALB를 배치하고 공용 인터넷 트래픽(`0.0.0.0/0:80`)을 수신하도록 ALB 전용 보안 그룹을 생성합니다.
3. **EC2 인스턴스를 Private Subnet으로 격리**: 웹 서버 EC2 인스턴스들은 외부에서 직접 접근할 수 없는 Private Subnet에 배치합니다.
4. **보안 그룹 체이닝(Security Group Chaining)**:
   * EC2 인스턴스의 보안 그룹 인바운드 소스를 `0.0.0.0/0`이 아니라 **ALB의 보안 그룹 ID (`sg-alb-xxxx`)**로만 지정합니다.
   * 이렇게 구성하면 인터넷의 어떤 클라이언트도 EC2에 직접 접근할 수 없으며, 오직 검증된 ALB를 통과한 정상 트래픽만 웹 서버에 도달하게 되어 보안성이 극대화됩니다.
