# B6-1 Cloud Resource Cleanup Checklist

> 과금 방지를 위한 **Phase C Runtime 종료 Gate**입니다. 삭제 버튼을 누르기 전에 실제 사용 중인 공유 리소스인지 확인합니다. B6-1에서 만든 리소스만 정리합니다.

## 0. 식별

- [ ] 실습 Region 기록
- [ ] B6-1에서 생성한 VPC ID 기록
- [ ] Public Subnet ID 기록
- [ ] Internet Gateway ID 기록
- [ ] Route Table ID 기록
- [ ] Security Group ID 기록
- [ ] EC2 Instance ID 기록
- [ ] 사용 IAM User/Role/Policy 식별
- [ ] Key Pair가 B6-1 전용인지 확인

## 1. Evidence 확보 후 정리

삭제 전에 필요한 외부 접속/Architecture/Troubleshooting/Evaluation Evidence를 먼저 확보합니다.

- [ ] 외부 HTTP 200 Evidence
- [ ] localhost HTTP 200 Evidence
- [ ] outbound Internet Evidence
- [ ] Security Group Evidence
- [ ] Route/IGW/VPC Evidence
- [ ] IAM 최소권한 Evidence

## 2. EC2

- [ ] EC2 Instance 종료(Terminate)
- [ ] Instance가 `terminated` 상태가 되었는지 확인
- [ ] Elastic IP를 별도로 생성했다면 연결 해제 및 Release
- [ ] 추가 EBS Volume/Snapshot을 생성했다면 B6-1 전용 여부 확인 후 삭제

## 3. Network

일반적으로 의존성이 적은 것부터 제거합니다.

- [ ] B6-1 Security Group 삭제
- [ ] custom Route Table association 해제/정리
- [ ] custom Route Table 삭제
- [ ] Internet Gateway를 VPC에서 detach
- [ ] Internet Gateway 삭제
- [ ] Public Subnet 삭제
- [ ] VPC 삭제

AWS가 dependency 오류를 반환하면 강제 우회하지 말고 해당 VPC에 남은 ENI/Instance/Route/SG/IGW 의존성을 먼저 확인합니다.

## 4. IAM / Key Material

- [ ] B6-1 전용 IAM User/Role/Policy라면 다른 사용 여부 확인 후 제거
- [ ] 실습용 Access Key를 만들었다면 비활성/삭제
- [ ] B6-1 전용 Key Pair라면 필요 여부 확인 후 AWS 측 Key Pair 삭제
- [ ] Local Private Key는 향후 필요 여부를 판단해 안전하게 관리하며 GitHub에는 넣지 않음

## 5. 최종 과금 점검

- [ ] 해당 Region EC2 Instance 0개 또는 B6-1 Instance 없음
- [ ] B6-1 Elastic IP 없음
- [ ] B6-1 추가 Volume/Snapshot 없음
- [ ] B6-1 VPC/IGW/Subnet/SG가 남지 않음
- [ ] Billing / Cost Explorer에서 예상치 못한 과금 리소스가 없는지 확인

## 완료 기록

- 정리 시각: TODO_RUNTIME
- Region: TODO_RUNTIME
- 최종 확인자: TODO_RUNTIME
- 비고: TODO_RUNTIME
