# 리소스 정리 체크리스트 및 삭제 증빙 — b6-1

> **실습 종료 후 반드시 의존성 역순으로 실행**할 것. 역순으로 삭제해야 종속성 충돌(DependencyViolation) 없이 안전하게 정리됩니다.  
> 모든 명령 실행 기준: `--profile b6user --region ap-northeast-2`

---

## 1. 리소스 식별 정보 및 최종 정리 상태

| 리소스 구분 | 고유 ID / 이름 | 정리 상태 | 콘솔 증빙 스크린샷 |
|---|---|---|---|
| **EC2 인스턴스** | `i-05d106a3c3409edd4` | **종료 완료 (terminated)** | [종료 요청](file:///Users/mpeg46551/b3_1/screenshots/23-ec2-termination-request.jpg) / [종료 완료](file:///Users/mpeg46551/b3_1/screenshots/24-ec2-terminated.jpg) |
| **루트 EBS 볼륨** | `vol-07a010a8788f128a1` | **자동 삭제 완료 (부재)** | [EBS 부재 확인](file:///Users/mpeg46551/b3_1/screenshots/25-ebs-deleted.jpg) |
| **Elastic IP** | 미생성 (자동배정 공인 IP) | **잔존 없음 (0개)** | [EIP 없음 증빙](file:///Users/mpeg46551/b3_1/screenshots/31-eip-none.jpg) |
| **Key Pair** | `b6-keypair` | **삭제 완료** | [키페어 삭제 완료](file:///Users/mpeg46551/b3_1/screenshots/26-key-deleted.jpg) |
| **Security Group** | `sg-06a53efc080f4c3c6` | **삭제 완료 (기본 SG 보존)** | [실습 SG 삭제](file:///Users/mpeg46551/b3_1/screenshots/36-lab-sg-deleted.jpg) / [기본 SG 보존](file:///Users/mpeg46551/b3_1/screenshots/37-default-sg-preserved.jpg) |
| **Public Subnet** | `subnet-01c319e79337bc3b0` | **삭제 완료** | [서브넷 부재 확인](file:///Users/mpeg46551/b3_1/screenshots/32-subnet-deleted.jpg) |
| **Route Table** | `rtb-05896b293836ba38e` | **삭제 완료** | [퍼블릭 RT 삭제](file:///Users/mpeg46551/b3_1/screenshots/33-public-rt-deleted.jpg) / [기본 RT 부재](file:///Users/mpeg46551/b3_1/screenshots/34-main-rt-deleted.jpg) |
| **Internet Gateway**| `igw-0216170a9e1876f6f` | **분리 및 삭제 완료** | [IGW 삭제 완료](file:///Users/mpeg46551/b3_1/screenshots/30-igw-deleted.jpg) |
| **VPC** | `vpc-023d852a3471ef158` | **삭제 완료 (기본 VPC 보존)** | [VPC 삭제 계획](file:///Users/mpeg46551/b3_1/screenshots/27-vpc-delete-plan.jpg) / [VPC 삭제 성공](file:///Users/mpeg46551/b3_1/screenshots/28-vpc-deleted.jpg) / [기본 VPC 보존](file:///Users/mpeg46551/b3_1/screenshots/29-default-vpc-preserved.jpg) |
| **IAM User/Key** | `codyssey-b6-user` | **키 삭제 및 정리 수립** | [정리 확인 창](file:///Users/mpeg46551/b3_1/screenshots/20-cleanup-confirmation.jpg) |

---

## 2. 단계별 정리 절차 및 실제 CLI 출력 스냅샷

### 1단계: EC2 인스턴스 종료 (Terminate)

* **콘솔 증빙**: [종료 요청 창](file:///Users/mpeg46551/b3_1/screenshots/23-ec2-termination-request.jpg), [종료 완료 확인](file:///Users/mpeg46551/b3_1/screenshots/24-ec2-terminated.jpg)

```bash
# 1. 인스턴스 종료 명령 실행
$ aws ec2 terminate-instances \
  --instance-ids i-05d106a3c3409edd4 \
  --profile b6user --region ap-northeast-2
```
```json
// 실제 반환된 CLI 출력 결과
{
    "TerminatingInstances": [
        {
            "CurrentState": {
                "Code": 32,
                "Name": "shutting-down"
            },
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            },
            "InstanceId": "i-05d106a3c3409edd4"
        }
    ]
}
```

```bash
# 2. 종료 완료 대기 및 상태 확인
$ aws ec2 wait instance-terminated \
  --instance-ids i-05d106a3c3409edd4 \
  --profile b6user --region ap-northeast-2

$ aws ec2 describe-instances --instance-ids i-05d106a3c3409edd4 \
  --query 'Reservations[0].Instances[0].State.Name' --output text
terminated
```

- [x] EC2 인스턴스 상태 `terminated` 확인 및 공인 IP 자동 회수 완료

---

### 2단계: EBS 볼륨 잔여 여부 확인

* **콘솔 증빙**: [EBS 볼륨 목록 부재 증빙](file:///Users/mpeg46551/b3_1/screenshots/25-ebs-deleted.jpg)

루트 볼륨은 `DeleteOnTermination=true` 속성으로 인해 인스턴스 종료와 함께 자동 소멸됩니다.

```bash
# 잔여 available(미연결) 볼륨 확인
$ aws ec2 describe-volumes \
  --filters "Name=status,Values=available" \
  --profile b6user --region ap-northeast-2 \
  --query 'Volumes[*].[VolumeId,Size,State]' --output table
```
```text
# 실행 결과: 반환 행 없음 (0개)
```
- [x] 미사용 잔여 EBS 볼륨 없음 확인

---

### 3단계: Elastic IP (EIP) 잔여 확인

* **콘솔 증빙**: [EIP 목록 부재 증빙](file:///Users/mpeg46551/b3_1/screenshots/31-eip-none.jpg)

본 실습에서는 비용 발생 위험이 있는 고정 Elastic IP를 할당하지 않고, 서브넷 기본 자동 배정 퍼블릭 IP를 활용했습니다.

```bash
$ aws ec2 describe-addresses \
  --profile b6user --region ap-northeast-2 \
  --query 'Addresses[*].[PublicIp,AllocationId]' --output text
```
```text
# 실행 결과: 반환 내용 없음 (미사용 및 잔존 주소 없음)
```
- [x] Elastic IP 잔존 없음 확인

---

### 4단계: 키 페어 삭제

* **콘솔 증빙**: [키 페어 삭제 확인](file:///Users/mpeg46551/b3_1/screenshots/26-key-deleted.jpg)

```bash
$ aws ec2 delete-key-pair --key-name b6-keypair \
  --profile b6user --region ap-northeast-2

# 삭제 확인
$ aws ec2 describe-key-pairs --key-names b6-keypair \
  --profile b6user --region ap-northeast-2
```
```text
An error occurred (InvalidKeyPair.NotFound) when calling the DescribeKeyPairs operation: The key pair 'b6-keypair' does not exist
```
- [x] 키 페어 AWS 상에서 완전 삭제 완료
- [x] 로컬 `b6-keypair.pem` 파일 폐기 완료

---

### 5단계: Security Group 삭제

* **콘솔 증빙**: [실습 SG 부재 증빙](file:///Users/mpeg46551/b3_1/screenshots/36-lab-sg-deleted.jpg), [기본 VPC의 default SG 보존 증빙](file:///Users/mpeg46551/b3_1/screenshots/37-default-sg-preserved.jpg)

인스턴스 종료 후 네트워크 인터페이스(ENI)가 해제되면 보안 그룹을 삭제합니다.

```bash
$ aws ec2 delete-security-group \
  --group-id sg-06a53efc080f4c3c6 \
  --profile b6user --region ap-northeast-2
```
```json
// 반환값: 성공 시 빈 JSON 객체 반환
{}
```
- [x] 실습 전용 보안 그룹 삭제 완료

---

### 6단계: Route Table 연결 해제 및 삭제

* **콘솔 증빙**: [퍼블릭 RT 부재 증빙](file:///Users/mpeg46551/b3_1/screenshots/33-public-rt-deleted.jpg), [VPC 기본 RT 부재 증빙](file:///Users/mpeg46551/b3_1/screenshots/34-main-rt-deleted.jpg)

```bash
# 1. 서브넷 라우팅 연결 해제
$ aws ec2 disassociate-route-table \
  --association-id rtbassoc-02da8b0e4b675fb29 \
  --profile b6user --region ap-northeast-2

# 2. 라우팅 테이블 삭제
$ aws ec2 delete-route-table \
  --route-table-id rtb-05896b293836ba38e \
  --profile b6user --region ap-northeast-2
```
- [x] 라우트 테이블 정상 삭제 완료

---

### 7단계: 서브넷 삭제

* **콘솔 증빙**: [서브넷 부재 증빙](file:///Users/mpeg46551/b3_1/screenshots/32-subnet-deleted.jpg)

```bash
$ aws ec2 delete-subnet \
  --subnet-id subnet-01c319e79337bc3b0 \
  --profile b6user --region ap-northeast-2
```
- [x] 퍼블릭 서브넷 삭제 완료

---

### 8단계: Internet Gateway 분리(Detach) 및 삭제

* **콘솔 증빙**: [IGW 삭제 완료 확인](file:///Users/mpeg46551/b3_1/screenshots/30-igw-deleted.jpg)

```bash
# 1. VPC에서 Detach
$ aws ec2 detach-internet-gateway \
  --internet-gateway-id igw-0216170a9e1876f6f \
  --vpc-id vpc-023d852a3471ef158 \
  --profile b6user --region ap-northeast-2

# 2. IGW 삭제
$ aws ec2 delete-internet-gateway \
  --internet-gateway-id igw-0216170a9e1876f6f \
  --profile b6user --region ap-northeast-2
```
- [x] Internet Gateway 완전 삭제 완료

---

### 9단계: VPC 삭제 및 기존 기본 VPC 보존

* **콘솔 증빙**: [VPC 삭제 계획 화면](file:///Users/mpeg46551/b3_1/screenshots/27-vpc-delete-plan.jpg), [VPC 삭제 성공 화면](file:///Users/mpeg46551/b3_1/screenshots/28-vpc-deleted.jpg), [기본 VPC 보존 확인](file:///Users/mpeg46551/b3_1/screenshots/29-default-vpc-preserved.jpg)

```bash
$ aws ec2 delete-vpc \
  --vpc-id vpc-023d852a3471ef158 \
  --profile b6user --region ap-northeast-2
```
- [x] 실습 전용 VPC(`vpc-023d852a3471ef158`) 삭제 완료
- [x] AWS 기본 VPC(Default VPC)는 절대 삭제하지 않고 안전하게 보존 완료

---

### 10단계: IAM 자격증명 정리 (루트/관리자 계정)

```bash
# 1. Access Key 비활성화 및 삭제
$ aws iam update-access-key --user-name codyssey-b6-user --access-key-id AKIAUXZY3NKTUZW4TSVO --status Inactive
$ aws iam delete-access-key --user-name codyssey-b6-user --access-key-id AKIAUXZY3NKTUZW4TSVO

# 2. 인라인 정책 삭제
$ aws iam delete-user-policy --user-name codyssey-b6-user --policy-name B6LabMinimumPrivilege

# 3. 실습 유저 삭제
$ aws iam delete-user --user-name codyssey-b6-user
```
- [x] 실습용 IAM 자격증명 및 권한 정리 완료

---

## 3. 최종 잔존 리소스 일괄 확인 CLI

```bash
# 1. 프로젝트 태그 기반 EC2 인스턴스 확인
$ aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=codyssey-b6-1" \
  --profile b6user --region ap-northeast-2 \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
-------------------------------------------------
|               DescribeInstances               |
+----------------------+------------------------+
|  i-05d106a3c3409edd4 |  terminated            |
+----------------------+------------------------+

# 2. 실습 VPC 잔여 확인
$ aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=codyssey-b6-1" \
  --profile b6user --region ap-northeast-2 \
  --query 'Vpcs[*].VpcId' --output text
# 출력: 없음 (정상 삭제 완료)
```
