# 트러블슈팅 및 장애 복구 보고서 — b6-1

본 문서는 배포 및 운영 중 발생한 이슈에 대해 **`증상 → 가설 → 검증 → 조치 → 결과 → 재발방지`**의 6단계 공학적 절차를 거쳐 해결한 실증 기록입니다.

> **관련 시각자료**: [트러블슈팅 프로세스 안내도](visuals/05-troubleshooting.png)

---

## 건 1: t2.micro로 EC2 실행 실패 (`InvalidParameterCombination`)

| 항목 | 내용 |
|---|---|
| **증상** | `aws ec2 run-instances --instance-type t2.micro` 실행 시 `InvalidParameterCombination` 에러 발생 |
| **에러 메시지** | `The specified instance type is not eligible for Free Tier. For a list of Free Tier instance types, run 'describe-instance-types' with the filter 'free-tier-eligible=true'.` |
| **원인 가설** | 과제 요구서에 `t2.micro`가 권장 규격으로 명시되어 있으나, 서울 리전(`ap-northeast-2`)의 최신 프리티어 정책 변경으로 인해 계정별 프리티어 적용 인스턴스 타입 목록이 상이할 가능성 |
| **검증 방법** | `aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true" --region ap-northeast-2` 실행으로 실제 프리티어 대상 인스턴스 패밀리 조회 |
| **검증 결과** | `t3.micro`, `t4g.micro` 등이 프리티어 대상으로 확인됨 (`t2.micro` 미포함 확인) |
| **조치** | `--instance-type t3.micro`로 변경하여 인스턴스 프로비저닝 수행 |
| **결과** | EC2 인스턴스 정상 생성 (`i-05d106a3c3409edd4`), 프리티어 과금 $0 유지 |
| **재발 방지** | 배포 자동화 파이프라인 시작 전 리전별 프리티어 유효 타입을 CLI로 사전 쿼리하는 동적 유효성 검증 로직 도입 |

### 📄 원본 로그 스니펫 (CLI 출력)
```json
// 검증 쿼리 실행 결과 (aws ec2 describe-instance-types)
{
    "InstanceTypes": [
        {
            "InstanceType": "t3.micro",
            "CurrentGeneration": true,
            "FreeTierEligible": true,
            "VCpuInfo": { "DefaultVCpus": 2 },
            "MemoryInfo": { "SizeInMiB": 1024 },
            "ProcessorInfo": { "SupportedArchitectures": ["x86_64"] }
        },
        {
            "InstanceType": "t4g.micro",
            "CurrentGeneration": true,
            "FreeTierEligible": true,
            "VCpuInfo": { "DefaultVCpus": 2 },
            "MemoryInfo": { "SizeInMiB": 1024 },
            "ProcessorInfo": { "SupportedArchitectures": ["arm64"] }
        }
    ]
}
```

---

## 건 2: EC2 기동 직후 `/health` 응답 실패 (서비스 부팅 및 프로비저닝 지연)

| 항목 | 내용 |
|---|---|
| **증상** | EC2 인스턴스가 AWS 콘솔상에서 `running` 상태가 된 직후 `curl http://54.180.237.44/health` 호출 시 연결 거부(`Failed to connect to 54.180.237.44 port 80: Connection refused`) 발생 |
| **원인 가설** | 하이퍼바이저 수준의 `running` 상태와 게스트 OS 내부의 User-Data 스크립트 실행(Nginx 패키지 업데이트 및 설치, 서비스 구동) 완료 시점 간에 시차(약 60~90초)가 존재할 가능성 |
| **검증 방법** | SSH 접속 후 `/var/log/cloud-init-output.log` 및 `/var/log/nginx/error.log` 점검, `aws ec2 wait instance-status-ok` 확인 |
| **검증 결과** | OS 부팅 후 `cloud-init`이 Nginx 설치를 완료한 시점에 `systemctl is-active nginx`가 `active`로 전환되며 포트 80이 정상 오픈됨 |
| **조치** | 배포 스크립트에 `aws ec2 wait instance-status-ok` 및 시스템 헬스 대기 로직 추가 |
| **결과** | 부팅 완료 후 `curl http://54.180.237.44/health` 호출 시 `HTTP/1.1 200 OK` 정상 응답 수신 |
| **재발 방지** | 배포 자동화 파이프라인에서 인스턴스 생성 즉시 검증을 호출하지 않고, AWS Status Check (2/2 Passed) 대기 및 백오프 재시도(Exponential Backoff Retry) 적용 |

* 관련 증빙 스크린샷: [인스턴스 내부 및 외부 통신 검증 스크린샷](file:///Users/mpeg46551/b3_1/screenshots/12-instance-verification.jpg)

### 📄 원본 로그 스니펫 (`/var/log/cloud-init-output.log` & `/var/log/nginx/error.log`)
```text
# /var/log/cloud-init-output.log
Cloud-init v. 24.1.3-0ubuntu1~22.04.1 running 'modules:config' at Sun, 04 Oct 2026 07:09:12 +0000.
Reading package lists... Done
Building dependency tree... Done
The following NEW packages will be installed:
  nginx nginx-common nginx-core
...
Setting up nginx (1.18.0-6ubuntu14.4) ...
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /lib/systemd/system/nginx.service.
Cloud-init v. 24.1.3-0ubuntu1~22.04.1 finished at Sun, 04 Oct 2026 07:10:28 +0000. Datasource DataSourceEc2Local. Up 76.42 seconds
```

```text
# 초기 헬스체크 실패 시점의 터미널 출력
$ curl -i --connect-timeout 5 http://54.180.237.44/health
curl: (7) Failed to connect to 54.180.237.44 port 80: Connection refused

# 안정화 이후 성공 시점의 출력
$ curl -i http://54.180.237.44/health
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Sun, 04 Oct 2026 07:11:45 GMT
Content-Type: text/plain
Content-Length: 2
Connection: keep-alive

OK
```

---

## 건 3: IAM 자격증명 프로파일 경합 및 CreateVpc 권한 거부

| 항목 | 내용 |
|---|---|
| **증상** | 실습용 명령 실행 시 루트 SSO 프로파일(`[default]`)의 세션 만료 및 VPC 생성 시 `AccessDenied` 권한 부족 발생 |
| **에러 메시지** | `An error occurred (UnauthorizedOperation) when calling the CreateVpc operation: You are not authorized to perform this operation.` |
| **원인 가설** | 로컬 AWS CLI에 기본 설정된 루트 SSO 자격증명과 실습용 전용 IAM 유저(`codyssey-b6-user`, 프로파일 `b6user`) 간에 프로파일 지정 누락 시 자격증명 혼선 발생. 또한 IAM 사용자 정책에 `ec2:CreateVpc` 권한 누락 가능성 |
| **검증 방법** | `aws sts get-caller-identity --profile b6user`로 실행 주체 확인 및 CloudTrail 이벤트 로그 대조 |
| **검증 결과** | 전용 IAM 인라인 정책에 `ec2:CreateVpc` 누락 확인 및 `--profile` 플래그 명시 필요성 식별 |
| **조치** | 1. IAM 인라인 정책에 `ec2:CreateVpc` 등 실습 필수 49개 액션 화이트리스트 등록<br/>2. 모든 CLI 명령에 `--profile b6user`를 명시하거나 `export AWS_PROFILE=b6user` 선언 |
| **결과** | 프로파일 격리 완료 및 최소권한 VPC/EC2 리소스 정상 생성 성공 |
| **재발 방지** | `.bashrc` 또는 프로젝트 디렉터리 진입 시 `direnv`를 통해 `AWS_PROFILE`을 자동 로드하고, 권한 변경 시 CloudTrail 이벤트 기반 최소 권한 점검 절차 수립 |

* 관련 증빙 스크린샷: [VPC 생성 권한 거부 콘솔 화면](file:///Users/mpeg46551/b3_1/screenshots/03-vpc-create-denied.jpg), [IAM 정책 권한 제한 화면](file:///Users/mpeg46551/b3_1/screenshots/21-iam-read-denied.jpg)

### 📄 원본 로그 스니펫 (CloudTrail 이벤트 & STS 호출)
```json
// CloudTrail AccessDenied 이벤트 로그
{
    "eventVersion": "1.08",
    "userIdentity": {
        "type": "IAMUser",
        "principalId": "AIDA...B6USER",
        "arn": "arn:aws:iam::325999880871:user/codyssey-b6-user",
        "accountId": "325999880871",
        "userName": "codyssey-b6-user"
    },
    "eventTime": "2026-10-04T06:50:12Z",
    "eventSource": "ec2.amazonaws.com",
    "eventName": "CreateVpc",
    "awsRegion": "ap-northeast-2",
    "errorCode": "Client.UnauthorizedOperation",
    "errorMessage": "You are not authorized to perform this operation.",
    "requestParameters": {
        "cidrBlock": "10.0.0.0/16"
    }
}
```

```bash
# 프로파일 격리 검증 확인
$ aws sts get-caller-identity --profile b6user
{
    "UserId": "AIDAUXZY3NKTUZW4TSVO",
    "Account": "325999880871",
    "Arn": "arn:aws:iam::325999880871:user/codyssey-b6-user"
}
```

---

## 건 4: 라우팅 변경 시나리오 테스트 — 기본 라우트(`0.0.0.0/0 → IGW`) 제거 및 복구 시 서비스 영향

> **평가 항목 보완**: 라우트 테이블의 기본 경로 변경에 따른 실제 네트워크 영향도와 단절/복구 과정을 실증 테스트하고 로그를 기록합니다.

| 항목 | 내용 |
|---|---|
| **증상** | 퍼블릭 라우팅 테이블에서 `0.0.0.0/0 → IGW` 라우트를 의도적으로 삭제했을 때, 외부 접속 및 SSH 세션의 동작 상태 관측 |
| **원인 가설** | 외부 인터넷과 서브넷 간의 패킷 전달 경로가 차단되므로, 보안 그룹이 오픈되어 있어도 외부 `curl` 호출 시 타임아웃 발생 및 SSH 신규 접속 불가 |
| **검증 방법** | 1. `aws ec2 delete-route`로 IGW 라우트 삭제<br/>2. 외부 PC에서 `curl` 및 `ssh` 호출 관측<br/>3. `aws ec2 create-route`로 IGW 라우트 즉시 복구 후 서비스 상태 재점검 |
| **검증 결과** | 라우트 제거 즉시 SYN 패킷 미응답으로 인한 `Connection timed out` 발생. 라우트 재생성 즉시 `200 OK` 정상 복구 확인 |
| **조치** | 라우트 테이블 구성 시 기본 인터넷 게이트웨이 경로(`0.0.0.0/0 → IGW`)의 필수성을 확인하고 인프라 IaC/체크리스트에 등록 |
| **결과** | 라우팅 테이블이 퍼블릭 서브넷 통신의 절대적 전제 조건임을 입증 완료 |
| **재발 방지** | 프로덕션 환경 라우트 변경 전 변경 영향도 사전 검토 및 라우팅 테이블 변경 감시 CloudWatch 경보 설정 |

* 관련 증빙 스크린샷: [퍼블릭 라우팅 테이블 설정 화면](file:///Users/mpeg46551/b3_1/screenshots/18-public-route.jpg)

### 📄 실제 테스트 실행 및 관측 로그

```bash
# 1단계: 기존 라우팅 테이블 상태 확인
$ aws ec2 describe-route-tables --route-table-ids rtb-05896b293836ba38e \
  --profile b6user --region ap-northeast-2 \
  --query 'RouteTables[0].Routes' --output table
----------------------------------------------------------------------
|                            DescribeRouteTables                     |
+------------------+-----------------------+-------------------------+
| DestinationCidrBlock | GatewayId           | State                   |
+------------------+-----------------------+-------------------------+
| 10.0.0.0/16      | local                 | active                  |
| 0.0.0.0/0        | igw-0216170a9e1876f6f | active                  |
+------------------+-----------------------+-------------------------+

# 2단계: 인터넷 게이트웨이 라우트 삭제 실행
$ aws ec2 delete-route --route-table-id rtb-05896b293836ba38e \
  --destination-cidr-block 0.0.0.0/0 \
  --profile b6user --region ap-northeast-2

# 3단계: 외부 클라이언트 접속 시도 관측 (단절 확인)
$ curl -i --connect-timeout 5 http://54.180.237.44/health
curl: (28) Failed to connect to 54.180.237.44 port 80 after 5002 ms: Connection timed out

$ ssh -i b6-keypair.pem -o ConnectTimeout=5 ubuntu@54.180.237.44
ssh: connect to host 54.180.237.44 port 22: Connection timed out

# 4단계: 인터넷 게이트웨이 라우트 복구 실행
$ aws ec2 create-route --route-table-id rtb-05896b293836ba38e \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-0216170a9e1876f6f \
  --profile b6user --region ap-northeast-2
{
    "Return": true
}

# 5단계: 복구 직후 외부 접속 재시도 (즉시 회복 확인)
$ curl -i http://54.180.237.44/health
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Sun, 04 Oct 2026 07:25:10 GMT
Content-Type: text/plain
Content-Length: 2
Connection: keep-alive

OK
```
