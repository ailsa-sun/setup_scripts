#!/usr/bin/env bash
set -euo pipefail

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}→${NC} $1"; }
success() { echo -e "${GREEN}✔${NC} $1"; }
error()   { echo -e "${RED}✖${NC} $1" >&2; }

# ─── Usage ───
usage() {
    echo "Usage: $0 -i <ip_address> -n <name> -u <user>"
    echo ""
    echo "  -i    IP address or hostname of the remote machine"
    echo "  -n    Friendly name for the machine (used in SSH config & alias)"
    echo "  -u    SSH username on the remote machine"
    echo "  -h    Show this help message"
    exit 1
}

# ─── Parse args ───
while getopts "i:n:u:h" opt; do
    case "$opt" in
        i) IP="$OPTARG" ;;
        n) NAME="$OPTARG" ;;
        u) USER="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [[ -z "${IP:-}" || -z "${NAME:-}" || -z "${USER:-}" ]]; then
    error "All arguments are required."
    usage
fi

# ══════════════════════════════════════════════
#  OS Detection — Local
# ══════════════════════════════════════════════
detect_local_os() {
    case "${OSTYPE:-}" in
        msys*|cygwin*|win32*) echo "windows"; return ;;
    esac
    case "$(uname -s 2>/dev/null)" in
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        Darwin*)              echo "macos"   ;;
        *)                    echo "linux"   ;;
    esac
}

LOCAL_OS="$(detect_local_os)"
info "Local OS detected: $LOCAL_OS"

# ── Local paths ──
if [[ "$LOCAL_OS" == "windows" ]]; then
    # Resolve the actual Windows username and build C:/Users/<user> paths
    WIN_USER="${USERNAME:-$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' || whoami | sed 's/.*\\//')}"
    WIN_HOME="C:/Users/$WIN_USER"

    # Git Bash working paths (used for mkdir, keygen, etc.)
    SSH_DIR="$(cygpath -u "$WIN_HOME/.ssh" 2>/dev/null || echo "$HOME/.ssh")"
    KEY_FILE="$SSH_DIR/$NAME"
    CONFIG_FILE="$SSH_DIR/config"

    # Native Windows paths (used in SSH config & .bat wrappers)
    WIN_SSH_DIR="C:/Users/$WIN_USER/.ssh"
    WIN_KEY_FILE="$WIN_SSH_DIR/$NAME"
    WIN_CONFIG_FILE="$WIN_SSH_DIR/config"

    SHELL_RC="$HOME/.bashrc"
else
    # Linux / macOS — use ~/.ssh
    SSH_DIR="$HOME/.ssh"
    KEY_FILE="$SSH_DIR/$NAME"
    CONFIG_FILE="$SSH_DIR/config"

    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bashrc"
    fi
fi

# ══════════════════════════════════════════════
#  OS Detection — Remote
# ══════════════════════════════════════════════
info "Detecting remote OS on $USER@$IP ..."

REMOTE_OS="linux"
REMOTE_UNAME="$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
    "$USER@$IP" "uname -s" 2>/dev/null || echo "")"

if [[ -z "$REMOTE_UNAME" ]]; then
    # uname failed — try Windows cmd
    REMOTE_VER="$(ssh -o ConnectTimeout=10 "$USER@$IP" "cmd.exe /c ver" 2>/dev/null || echo "")"
    if echo "$REMOTE_VER" | grep -qi "windows"; then
        REMOTE_OS="windows"
    fi
elif echo "$REMOTE_UNAME" | grep -qiE "MINGW|MSYS|CYGWIN"; then
    REMOTE_OS="windows"
elif echo "$REMOTE_UNAME" | grep -qi "Darwin"; then
    REMOTE_OS="macos"
else
    REMOTE_OS="linux"
fi

success "Remote OS detected: $REMOTE_OS"

# ══════════════════════════════════════════════
#  Step 1: Create local SSH directory & key
# ══════════════════════════════════════════════
mkdir -p "$SSH_DIR"
[[ "$LOCAL_OS" != "windows" ]] && chmod 700 "$SSH_DIR"

if [[ -f "$KEY_FILE" ]]; then
    info "Key '$KEY_FILE' already exists. Skipping generation."
else
    info "Generating SSH key: $KEY_FILE"
    ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "$NAME"
    success "Key generated."
fi

# ══════════════════════════════════════════════
#  Step 2: Copy public key to remote machine
# ══════════════════════════════════════════════
info "Copying public key to $USER@$IP ..."
echo "(You may be prompted for the remote password)"

if [[ "$REMOTE_OS" == "windows" ]]; then
    # Windows OpenSSH: check if user is admin
    # Admins use C:/ProgramData/ssh/administrators_authorized_keys
    # Regular users use C:/Users/<user>/.ssh/authorized_keys
    REMOTE_CMD='
        $sshDir = "C:\Users\$env:USERNAME\.ssh"
        if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }

        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        if ($isAdmin) {
            $authFile = "C:\ProgramData\ssh\administrators_authorized_keys"
        } else {
            $authFile = "C:\Users\$env:USERNAME\.ssh\authorized_keys"
        }

        $key = [Console]::In.ReadLine()
        Add-Content -Path $authFile -Value $key

        if ($isAdmin) {
            icacls $authFile /inheritance:r /grant "SYSTEM:(F)" /grant "Administrators:(F)" | Out-Null
        }

        Write-Host "KEY_TARGET=$authFile"
    '
    REMOTE_RESULT="$(cat "$KEY_FILE.pub" | ssh "$USER@$IP" "powershell -Command $REMOTE_CMD" 2>&1)"
    echo "$REMOTE_RESULT" | grep -q "KEY_TARGET=" && success "Key installed: $(echo "$REMOTE_RESULT" | grep KEY_TARGET= | cut -d= -f2-)"
else
    # Linux / macOS
    cat "$KEY_FILE.pub" | ssh "$USER@$IP" \
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    success "Public key installed on remote machine."
fi

# ══════════════════════════════════════════════
#  Step 3: Add entry to SSH config
# ══════════════════════════════════════════════

# IdentityFile path: Windows uses C:/Users/<user>/, Linux/macOS uses ~/.ssh/
if [[ "$LOCAL_OS" == "windows" ]]; then
    CONFIG_IDENTITY_PATH="$WIN_KEY_FILE"
else
    CONFIG_IDENTITY_PATH="~/.ssh/$NAME"
fi

if grep -q "^Host $NAME$" "$CONFIG_FILE" 2>/dev/null; then
    info "SSH config entry for '$NAME' already exists. Skipping."
else
    info "Adding SSH config entry for '$NAME' ..."
    touch "$CONFIG_FILE"
    [[ "$LOCAL_OS" != "windows" ]] && chmod 600 "$CONFIG_FILE"
    [[ -s "$CONFIG_FILE" ]] && [[ "$(tail -c 1 "$CONFIG_FILE")" != "" ]] && echo "" >> "$CONFIG_FILE"

    cat >> "$CONFIG_FILE" <<EOF

Host $NAME
    HostName $IP
    User $USER
    IdentityFile $CONFIG_IDENTITY_PATH
    IdentitiesOnly yes
EOF
    success "SSH config updated."
fi

# ══════════════════════════════════════════════
#  Step 4: Create SCP helper alias / doskey
# ══════════════════════════════════════════════
ALIAS_NAME="scp-$NAME"

if [[ "$LOCAL_OS" == "windows" ]]; then
    # In Git Bash, aliases still work via .bashrc
    # Also create a .bat wrapper for native CMD/PowerShell
    ALIAS_LINE="alias $ALIAS_NAME='scp -F \"$CONFIG_FILE\" -r $NAME'"
    BAT_FILE="$HOME/$ALIAS_NAME.bat"

    if [[ ! -f "$BAT_FILE" ]]; then
        cat > "$BAT_FILE" <<BATEOF
@echo off
scp -F "$WIN_CONFIG_FILE" -r $NAME %*
BATEOF
        success "Created $BAT_FILE for CMD/PowerShell"
    fi
else
    ALIAS_LINE="alias $ALIAS_NAME='scp -F $CONFIG_FILE -r $NAME'"
fi

if grep -q "alias $ALIAS_NAME=" "$SHELL_RC" 2>/dev/null; then
    info "Alias '$ALIAS_NAME' already exists in $SHELL_RC. Skipping."
else
    info "Adding alias '$ALIAS_NAME' to $SHELL_RC ..."
    touch "$SHELL_RC"
    cat >> "$SHELL_RC" <<EOF

# SCP shortcut for $NAME (added by ssh-setup.sh)
$ALIAS_LINE
EOF
    success "Alias added to $SHELL_RC"
fi

# ══════════════════════════════════════════════
#  Summary
# ══════════════════════════════════════════════
echo ""
echo -e "${BOLD}══════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Setup complete for '$NAME'${NC}"
echo -e "${BOLD}══════════════════════════════════════════════${NC}"
echo ""
echo -e "  Local OS:        ${CYAN}$LOCAL_OS${NC}"
echo -e "  Remote OS:       ${CYAN}$REMOTE_OS${NC}"
if [[ "$LOCAL_OS" == "windows" ]]; then
    echo -e "  Key file:        $WIN_KEY_FILE"
    echo -e "  SSH config:      $WIN_CONFIG_FILE"
else
    echo -e "  Key file:        $KEY_FILE"
    echo -e "  SSH config:      $CONFIG_FILE"
fi
echo ""
echo -e "  ${GREEN}ssh $NAME${NC}              → connect"
echo -e "  ${GREEN}scp-$NAME:/path .${NC}      → copy from remote"
echo -e "  ${GREEN}scp file $NAME:/path${NC}   → copy to remote"
echo ""
echo -e "  Run ${CYAN}source $SHELL_RC${NC} or open a new terminal"
echo -e "  to activate the scp-$NAME alias."
[[ "$LOCAL_OS" == "windows" ]] && echo -e "  For CMD/PowerShell: ${CYAN}$ALIAS_NAME.bat${NC} is also available."
echo ""
