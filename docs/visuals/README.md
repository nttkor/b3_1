# 처음 읽는 사람을 위한 그림 자료

모두 학습용 설명 그림이다. 실제 AWS 콘솔 캡처는 `../screenshots/`에 있으며, 자원 ID를 포함한 배포 당시 실제 구성은 [architecture.png](../architecture.png)에 있다. 아래 그림과 콘솔 증빙을 혼동하지 않는다.

1. [작은 가게로 이해하는 클라우드](01-cloud-shop.png): VPC·Subnet·EC2·IGW·RT·SG의 역할을 익힌다.
2. [웹 요청과 응답의 길](02-request-path.png): 외부 → IGW → Subnet → EC2 흐름과 성공 조건을 본다.
3. [IAM과 SG의 차이](03-iam-vs-sg.png): 관리 작업 허용과 서버 통신 허용을 구분한다.
4. [실습 전체 과정](04-lab-lifecycle.png): 준비·생성·검증·정리 및 중지/종료의 차이를 본다.
5. [문제 해결 순서](05-troubleshooting.png): 원인을 좁히고 하나씩 수정하는 순서를 익힌다.
6. [두 서버로 확장하는 예시](06-scale-out.png): ALB와 다중 AZ를 사용한 추가 설계다. 이번 실습에서 생성하지 않았다.

[쉬운 개념 설명](../beginner-guide.md)의 순서대로 읽은 다음, [Q&A](../evaluation-qa.md)의 Q6·Q11·Q14·Q16과 연결해 설명 연습을 할 수 있다. PNG 원본은 문서·발표 자료에 넣을 수 있도록 각각 1600×1000으로 저장했다.
