#!/usr/bin/env bash
# B6-1 R01 verification-only helper.
# Reference mode: file/design checks only.
# Runtime mode: read-only AWS describe/curl checks + actual Evidence gates.
# This script never creates, changes, or deletes AWS resources.

set -u

PASS=0
FAIL=0
MODE="${1:-reference}"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROUND_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
EVIDENCE_DIR="$ROUND_DIR/evidence/runtime"

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }
info() { echo "[INFO] $1"; }

for file in \
  "$ROUND_DIR/REFERENCE-BUILD.md" \
  "$ROUND_DIR/BEGINNER-GUIDE.md" \
  "$ROUND_DIR/CHECKLIST.md" \
  "$ROUND_DIR/reference/nginx/default.conf" \
  "$ROUND_DIR/reference/iam/least-privilege.md" \
  "$ROUND_DIR/docs/architecture.mmd" \
  "$ROUND_DIR/docs/requirements-mapping.md" \
  "$ROUND_DIR/docs/evaluation-qa.md" \
  "$ROUND_DIR/docs/troubleshooting.md" \
  "$ROUND_DIR/docs/cleanup-checklist.md" \
  "$ROUND_DIR/evidence/README.md"; do
    [ -f "$file" ] && pass "file exists: ${file#$ROUND_DIR/}" || fail "file missing: ${file#$ROUND_DIR/}"
done

NGINX="$ROUND_DIR/reference/nginx/default.conf"
ARCH="$ROUND_DIR/docs/architecture.mmd"
IAM_DOC="$ROUND_DIR/reference/iam/least-privilege.md"

if grep -Eq 'listen[[:space:]]+80' "$NGINX" && grep -Eq 'location[[:space:]]*=[[:space:]]*/health' "$NGINX" && grep -Eq 'return[[:space:]]+200[[:space:]]+.*OK' "$NGINX"; then
  pass "Nginx reference: port 80 + /health 200 OK"
else
  fail "Nginx reference port/health configuration"
fi

for pattern in 'VPC' 'Public Subnet' 'Internet Gateway' '0\.0\.0\.0/0.*IGW' 'Security Group' 'EC2' '80: 0\.0\.0\.0/0' '22: MY_IP/32'; do
  if grep -Eq "$pattern" "$ARCH"; then
    pass "architecture source: $pattern"
  else
    fail "architecture source missing: $pattern"
  fi
done

if grep -q 'AdministratorAccess' "$IAM_DOC" && grep -Eq 'S3/RDS|S3.*RDS' "$IAM_DOC" && grep -Eq 'Access Key|Secret Access Key|Session Token' "$IAM_DOC"; then
  pass "IAM guide covers admin prohibition, unrelated services, secret handling"
else
  fail "IAM least-privilege guide coverage"
fi

if grep -q 'TODO_RUNTIME' "$ROUND_DIR/docs/troubleshooting.md"; then
  info "Troubleshooting remains Runtime template"
else
  info "Troubleshooting template appears filled; actual evidence is checked only in Runtime mode"
fi

if grep -q 'TODO_RUNTIME' "$ROUND_DIR/docs/cleanup-checklist.md"; then
  info "Cleanup remains Runtime checklist"
else
  info "Cleanup checklist appears filled; actual resource absence is checked only in Runtime mode"
fi

if [ "$MODE" = "--runtime" ] || [ "$MODE" = "runtime" ]; then
  if ! command -v aws >/dev/null 2>&1; then
    fail "AWS CLI is required for runtime verify"
  else
    pass "AWS CLI command"
  fi

  if [ "${AWS_REGION:-}" = "ap-northeast-2" ]; then
    pass "AWS Region is ap-northeast-2"
  else
    fail "AWS_REGION must be ap-northeast-2 (current: ${AWS_REGION:-unset})"
  fi

  required_vars=(B6_VPC_ID B6_SUBNET_ID B6_IGW_ID B6_ROUTE_TABLE_ID B6_SG_ID B6_INSTANCE_ID B6_PUBLIC_IP B6_SSH_CIDR)
  missing=0
  for name in "${required_vars[@]}"; do
    if [ -n "${!name:-}" ]; then
      pass "runtime variable set: $name"
    else
      fail "runtime variable missing: $name"
      missing=$((missing + 1))
    fi
  done

  if [ "${B6_SSH_CIDR:-}" = "0.0.0.0/0" ]; then
    fail "SSH CIDR must never be 0.0.0.0/0"
  elif [[ "${B6_SSH_CIDR:-}" == */* ]]; then
    pass "SSH CIDR is explicitly scoped: $B6_SSH_CIDR"
  else
    fail "B6_SSH_CIDR must be CIDR such as x.x.x.x/32"
  fi

  if command -v aws >/dev/null 2>&1 && [ "$missing" -eq 0 ] && [ "${AWS_REGION:-}" = "ap-northeast-2" ]; then
    if aws ec2 describe-vpcs --region "$AWS_REGION" --vpc-ids "$B6_VPC_ID" --query 'Vpcs[0].VpcId' --output text 2>/dev/null | grep -qx "$B6_VPC_ID"; then
      pass "VPC exists"
    else
      fail "VPC exists"
    fi

    subnet_vpc=$(aws ec2 describe-subnets --region "$AWS_REGION" --subnet-ids "$B6_SUBNET_ID" --query 'Subnets[0].VpcId' --output text 2>/dev/null || true)
    [ "$subnet_vpc" = "$B6_VPC_ID" ] && pass "Subnet belongs to VPC" || fail "Subnet belongs to VPC"

    igw_vpc=$(aws ec2 describe-internet-gateways --region "$AWS_REGION" --internet-gateway-ids "$B6_IGW_ID" --query 'InternetGateways[0].Attachments[0].VpcId' --output text 2>/dev/null || true)
    [ "$igw_vpc" = "$B6_VPC_ID" ] && pass "Internet Gateway attached to VPC" || fail "Internet Gateway attachment"

    route_target=$(aws ec2 describe-route-tables --region "$AWS_REGION" --route-table-ids "$B6_ROUTE_TABLE_ID" --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].GatewayId | [0]" --output text 2>/dev/null || true)
    [ "$route_target" = "$B6_IGW_ID" ] && pass "0.0.0.0/0 route points to IGW" || fail "public default route"

    route_subnet=$(aws ec2 describe-route-tables --region "$AWS_REGION" --route-table-ids "$B6_ROUTE_TABLE_ID" --query "RouteTables[0].Associations[?SubnetId=='$B6_SUBNET_ID'].SubnetId | [0]" --output text 2>/dev/null || true)
    [ "$route_subnet" = "$B6_SUBNET_ID" ] && pass "Route Table associated with Public Subnet" || fail "Route Table/Public Subnet association"

    http_rule=$(aws ec2 describe-security-groups --region "$AWS_REGION" --group-ids "$B6_SG_ID" --query "SecurityGroups[0].IpPermissions[?IpProtocol=='tcp' && FromPort==\`80\` && ToPort==\`80\`].IpRanges[].CidrIp" --output text 2>/dev/null || true)
    echo "$http_rule" | tr '\t' '\n' | grep -qx '0.0.0.0/0' && pass "SG allows HTTP 80 from 0.0.0.0/0" || fail "SG HTTP rule"

    ssh_rules=$(aws ec2 describe-security-groups --region "$AWS_REGION" --group-ids "$B6_SG_ID" --query "SecurityGroups[0].IpPermissions[?IpProtocol=='tcp' && FromPort==\`22\` && ToPort==\`22\`].IpRanges[].CidrIp" --output text 2>/dev/null || true)
    if echo "$ssh_rules" | tr '\t' '\n' | grep -qx "$B6_SSH_CIDR" && ! echo "$ssh_rules" | tr '\t' '\n' | grep -qx '0.0.0.0/0'; then
      pass "SG SSH 22 is restricted to learner CIDR"
    else
      fail "SG SSH 22 restriction"
    fi

    all_open=$(aws ec2 describe-security-groups --region "$AWS_REGION" --group-ids "$B6_SG_ID" --query "SecurityGroups[0].IpPermissions[?IpProtocol=='-1'].IpRanges[].CidrIp" --output text 2>/dev/null || true)
    if echo "$all_open" | tr '\t' '\n' | grep -qx '0.0.0.0/0'; then
      fail "SG must not allow all traffic from 0.0.0.0/0"
    else
      pass "SG has no all-traffic 0.0.0.0/0 rule"
    fi

    instance_state=$(aws ec2 describe-instances --region "$AWS_REGION" --instance-ids "$B6_INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || true)
    [ "$instance_state" = "running" ] && pass "EC2 instance running" || fail "EC2 instance running ($instance_state)"

    instance_subnet=$(aws ec2 describe-instances --region "$AWS_REGION" --instance-ids "$B6_INSTANCE_ID" --query 'Reservations[0].Instances[0].SubnetId' --output text 2>/dev/null || true)
    [ "$instance_subnet" = "$B6_SUBNET_ID" ] && pass "EC2 is in Public Subnet" || fail "EC2/Public Subnet placement"

    instance_sgs=$(aws ec2 describe-instances --region "$AWS_REGION" --instance-ids "$B6_INSTANCE_ID" --query 'Reservations[0].Instances[0].SecurityGroups[].GroupId' --output text 2>/dev/null || true)
    echo "$instance_sgs" | tr '\t' '\n' | grep -qx "$B6_SG_ID" && pass "EC2 uses B6 Security Group" || fail "EC2 Security Group attachment"

    actual_public_ip=$(aws ec2 describe-instances --region "$AWS_REGION" --instance-ids "$B6_INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>/dev/null || true)
    [ "$actual_public_ip" = "$B6_PUBLIC_IP" ] && pass "EC2 Public IPv4 matches" || fail "EC2 Public IPv4 matches"

    if command -v curl >/dev/null 2>&1 && curl -fsS --max-time 10 "http://$B6_PUBLIC_IP/health" | grep -qx 'OK'; then
      pass "external /health returns HTTP success + OK"
    else
      fail "external /health returns OK"
    fi
  fi

  for file in aws-network.txt server.txt ssh.txt iam.md external.txt evaluation.md; do
    if [ -s "$EVIDENCE_DIR/$file" ]; then
      pass "runtime evidence: $file"
    else
      fail "runtime evidence missing/empty: $file"
    fi
  done

  if [ -s "$ROUND_DIR/docs/architecture.png" ] || [ -s "$ROUND_DIR/docs/architecture.pdf" ]; then
    pass "official architecture PNG/PDF exists"
  else
    fail "official architecture PNG/PDF missing"
  fi

  if grep -q 'TODO_RUNTIME' "$ROUND_DIR/docs/troubleshooting.md"; then
    fail "troubleshooting report still contains TODO_RUNTIME"
  else
    pass "troubleshooting report filled"
  fi

  if grep -q 'TODO_RUNTIME' "$ROUND_DIR/docs/cleanup-checklist.md"; then
    fail "cleanup checklist still contains TODO_RUNTIME"
  else
    pass "cleanup completion record filled"
  fi
fi

echo
printf 'Result: %d PASS / %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
