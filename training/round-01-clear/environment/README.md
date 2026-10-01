# B6-1 R01 Environment

## Phase A

Reference Build에서는 AWS 리소스를 생성하지 않습니다. 다음 도구와 구조만 준비합니다.

- AWS Console 또는 AWS CLI
- SSH client
- `curl`
- Nginx는 실제 EC2 Runtime에서 설치

## Phase C Runtime 변수

실제 생성한 값을 shell 환경변수에만 두고 GitHub에 저장하지 않습니다.

```bash
export AWS_REGION="ap-northeast-2"
export B6_VPC_ID="vpc-..."
export B6_SUBNET_ID="subnet-..."
export B6_IGW_ID="igw-..."
export B6_ROUTE_TABLE_ID="rtb-..."
export B6_SG_ID="sg-..."
export B6_INSTANCE_ID="i-..."
export B6_PUBLIC_IP="203.0.113.10"
```

위 값은 Secret은 아니지만 실제 Evidence에는 필요한 범위만 기록합니다. Access Key/Secret Access Key/Session Token/SSH Private Key는 절대 출력·커밋하지 않습니다.

## Nginx 설정 적용 원칙

EC2 안에서:

```text
현재 nginx 설정 확인
→ 기존 설정 백업
→ Reference config 반영
→ nginx -t
→ reload
→ curl localhost
→ curl localhost/health
```

실제 주요 명령은 `BEGINNER-GUIDE.md`에서 한 단계씩 직접 실행합니다.

## Verify

Reference 구조만:

```bash
bash training/round-01-clear/environment/verify.sh
```

실제 AWS 리소스를 읽기 전용으로 확인:

```bash
bash training/round-01-clear/environment/verify.sh --runtime
```

Runtime mode는 `aws ec2 describe-*`, `curl` 등 읽기 전용 검증만 수행하도록 설계합니다. 리소스를 생성/수정/삭제하지 않습니다.
