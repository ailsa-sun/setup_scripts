#!/bin/bash

# ─────────────────────────────────────────
#  SSH Connectivity Test Script
#  Add as many machines as you need below
# ─────────────────────────────────────────

MACHINES=(
  "bkinteldesktop"
  "cmujump"
  "cmuwin"
  "bwrcintellaptop"
  # add more here...
)

SSH_PORT=22        # Change if SSH runs on a non-standard port
SSH_TIMEOUT=5      # Seconds to wait before timing out
SSH_KEY=""         # Optional: path to private key e.g. ~/.ssh/id_rsa

# ─────────────────────────────────────────
#  Do not edit below this line
# ─────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

build_ssh_opts() {
  local opts="-o ConnectTimeout=$SSH_TIMEOUT -o BatchMode=yes -o StrictHostKeyChecking=no -p $SSH_PORT"
  [[ -n "$SSH_KEY" ]] && opts="$opts -i $SSH_KEY"
  echo "$opts"
}

test_ssh() {
  local index="$1"
  local target="$2"
  local opts
  opts=$(build_ssh_opts)

  printf "  [%2d] %-35s ... " "$index" "$target"

  ssh $opts "$target" "echo ok" &>/dev/null
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    echo -e "${GREEN}✔ SUCCESS${NC}"
    return 0
  else
    echo -e "${RED}✘ FAILED${NC} (exit code: $exit_code)"
    return 1
  fi
}

# ── Main ────────────────────────────────

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}        SSH Connectivity Test           ${NC}"
echo -e "${YELLOW}  Testing ${#MACHINES[@]} machine(s)                ${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

pass=0
fail=0
failed_hosts=()

for i in "${!MACHINES[@]}"; do
  machine="${MACHINES[$i]}"
  if test_ssh "$((i + 1))" "$machine"; then
    ((pass++))
  else
    ((fail++))
    failed_hosts+=("$machine")
  fi
done

echo ""
echo -e "${YELLOW}----------------------------------------${NC}"
echo -e "  Results: ${GREEN}$pass passed${NC}  |  ${RED}$fail failed${NC}  |  $((pass + fail)) total"
echo -e "${YELLOW}----------------------------------------${NC}"

if [[ ${#failed_hosts[@]} -gt 0 ]]; then
  echo -e "\n  ${RED}Failed hosts:${NC}"
  for host in "${failed_hosts[@]}"; do
    echo "    - $host"
  done
fi

echo ""
[[ $fail -eq 0 ]] && exit 0 || exit 1
