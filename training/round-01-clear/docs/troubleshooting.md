# B6-1 Troubleshooting Report — Runtime Template

> 이 문서는 실제 Phase C 오류/검증 기록으로 채웁니다. Reference 예시를 실제 장애 Evidence처럼 제출하지 않습니다.

## Case 1 — TODO_RUNTIME

### 1. Symptom — 증상

- 발생 시각: TODO_RUNTIME
- 사용자 관측: TODO_RUNTIME
- 실패한 요청/명령: TODO_RUNTIME
- 오류 메시지/상태코드: TODO_RUNTIME

### 2. Hypothesis — 가설

가능한 원인을 한 번에 모두 바꾸지 않고 우선순위로 적습니다.

1. TODO_RUNTIME
2. TODO_RUNTIME
3. TODO_RUNTIME

### 3. Verification — 검증

실제 확인 명령/화면:

```text
TODO_RUNTIME
```

확인 결과:

```text
TODO_RUNTIME
```

### 4. Action — 조치

원인이 확인된 뒤 필요한 설정만 변경합니다.

```text
TODO_RUNTIME
```

### 5. Result — 결과

Before:

```text
TODO_RUNTIME
```

After:

```text
TODO_RUNTIME
```

### 6. Recurrence Prevention — 재발 방지

- TODO_RUNTIME

---

## 권장 실습 장애 후보

실제 발생한 장애를 우선 기록합니다. 의도적으로 실습한다면 안전하고 복구 가능한 범위에서 다음 중 하나를 선택할 수 있습니다.

- Security Group에서 HTTP 80이 빠져 외부 접속 실패
- Route Table에 `0.0.0.0/0 → IGW`가 없어 외부 통신 실패
- Nginx가 정지되어 localhost HTTP 실패
- SSH source CIDR이 현재 Public IP와 달라 SSH 실패

실제 원인을 확인하기 전 설정을 여러 개 동시에 바꾸지 않습니다.

## 기본 진단 순서

외부 HTTP 장애:

```text
브라우저/curl 외부 실패
→ EC2 Public IPv4 확인
→ Security Group 80 확인
→ Public Subnet Route 0.0.0.0/0 → IGW 확인
→ EC2 안에서 curl localhost 확인
→ Nginx status / listen 80 확인
```

SSH 장애:

```text
현재 Public IP 확인
→ SG 22 source가 MY_IP/32인지 확인
→ Public IPv4 확인
→ route/IGW 확인
→ SSH key/user/permission 확인
```

Credential/Private Key/Token은 Report에 포함하지 않습니다.
