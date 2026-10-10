# 스크린샷 읽는 순서

JPG는 실제 콘솔·터미널·웹 화면이다. 생성 전 설정과 생성 후 증빙을 구분한다.

1. `01-ec2-baseline.jpg`: 실습 전 EC2 자원 수
2. `02-vpc-plan.jpg`: VPC 생성 전 설정
3. `03-vpc-create-denied.jpg`: 실제 권한 오류
4. `04-vpc-created.jpg`: 변경 후 생성 성공
5. `05-vpc-resource-map.jpg`: 실제 리소스 맵
6. `06-ec2-network-plan.jpg`: EIC 규칙 추가 전 초안
7. `07-key-pair-ready.jpg`: 키 생성 직전, 개인 키 저장 증빙 아님
8. `08-ec2-connect-plan.jpg`: 실행 전 최종 설정
9. `09-ec2-created.jpg`: EC2 생성 성공
10. `10-ssh-connect-settings.jpg`: 접속 설정
11. `11-ssh-connected.jpg`: SSH 성공
12. `12-instance-verification.jpg`: 서버 내부·외부 통신 검증
13. `13-external-web.jpg`: 외부 브라우저 웹 페이지
14. `15-instance-details.jpg`: 실행 중 EC2 상세
15. `16-storage.jpg`: 볼륨·종료 시 삭제
16. `17-security-rules.jpg`: 실제 SG 규칙
17. `18-public-route.jpg`: 활성 인터넷 경로·서브넷 연결
18. `19-igw-attached.jpg`: IGW Attached

번호 14는 잘못 붙은 `/health` 화면 이름을 제외하면서 비워 두었다. 외부 상태 응답은 `../evidence/external-health.txt`에 있다.

19. `20-cleanup-confirmation.jpg`: 삭제 실행 전 대상 확인
20. `21-iam-read-denied.jpg`: 본인 IAM 정책 조회 권한 제한
21. `22-security-sources.jpg`: 실제 인바운드 포트와 소스 대역

## 정리 실행과 완료 확인

실행 전 확인 창과 실행 후 결과를 구분한다. 아래 파일은 직접 캡처한 실제 콘솔 화면이다.

- [23-ec2-termination-request.jpg](23-ec2-termination-request.jpg): EC2 종료 요청 — 완료 상태와 구분
- [24-ec2-terminated.jpg](24-ec2-terminated.jpg): EC2 종료됨 및 공인 주소 해제
- [25-ebs-deleted.jpg](25-ebs-deleted.jpg): 실습 루트 EBS 부재
- [26-key-deleted.jpg](26-key-deleted.jpg): 키 페어 삭제 성공 및 빈 목록
- [27-vpc-delete-plan.jpg](27-vpc-delete-plan.jpg): VPC와 종속 자원 삭제 실행 전 대상 확인
- [28-vpc-deleted.jpg](28-vpc-deleted.jpg): VPC와 종속 자원 삭제 성공
- [29-default-vpc-preserved.jpg](29-default-vpc-preserved.jpg): 기존 기본 VPC 보존
- [30-igw-deleted.jpg](30-igw-deleted.jpg): 실습 IGW 부재
- [31-eip-none.jpg](31-eip-none.jpg): EIP 미생성·최종 잔존 없음
- [32-subnet-deleted.jpg](32-subnet-deleted.jpg): 실습 서브넷 부재
- [33-public-rt-deleted.jpg](33-public-rt-deleted.jpg): 실습 퍼블릭 라우팅 테이블 부재
- [34-main-rt-deleted.jpg](34-main-rt-deleted.jpg): 실습 VPC 자동 기본 라우팅 테이블 부재
- [35-acl-deleted.jpg](35-acl-deleted.jpg): 실습 VPC 자동 NACL 부재
- [36-lab-sg-deleted.jpg](36-lab-sg-deleted.jpg): 실습 보안 그룹 부재
- [37-default-sg-preserved.jpg](37-default-sg-preserved.jpg): 기존 기본 VPC의 기본 보안 그룹 하나만 보존

## 사용자 제공 원본

직접 캡처한 JPG 36장과 별도로 사용자 제공 이미지 11장을 보관했다. [추가 증빙 설명](../user-provided-evidence.md)에 초기·후속 상태와 해석의 한계가 있다. 평가문항 원본은 JPG이고 나머지는 PNG다.

- [billing-october-2026.png](user-provided/billing-october-2026.png)
- [blazed_fitzroy.png](user-provided/blazed_fitzroy.png)
- [credits-120.png](user-provided/credits-120.png)
- [current_instance.png](user-provided/current_instance.png)
- [ec2-credit-completed.png](user-provided/ec2-credit-completed.png)
- [ec2-terminated.png](user-provided/ec2-terminated.png)
- [ec2_bonus_credit_challenge.png](user-provided/ec2_bonus_credit_challenge.png)
- [evaluation-criteria.jpg](user-provided/evaluation-criteria.jpg)
- [key-deletion-confirmation.png](user-provided/key-deletion-confirmation.png)
- [vpc-before-delete.png](user-provided/vpc-before-delete.png)
- [vpc-deletion-confirmation.png](user-provided/vpc-deletion-confirmation.png)
