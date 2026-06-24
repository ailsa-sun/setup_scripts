#!/usr/bin/env bash
set -euo pipefail

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
    echo "Error: All arguments are required."
    usage
fi

SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/$NAME"
CONFIG_FILE="$SSH_DIR/config"
SHELL_RC="$HOME/.bashrc"

# Detect zsh
if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
    SHELL_RC="$HOME/.zshrc"
fi

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# ─── Step 1: Generate SSH key ───
if [[ -f "$KEY_FILE" ]]; then
    echo "Key '$KEY_FILE' already exists. Skipping generation."
else
    echo "Generating SSH key: $KEY_FILE"
    ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "$NAME"
    echo "Key generated."
fi

# ─── Step 2: Copy public key to remote machine ───
echo "Copying public key to $USER@$IP ..."
echo "(You may be prompted for the remote password)"
cat "$KEY_FILE.pub" | ssh "$USER@$IP" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
echo "Public key installed on remote machine."

# ─── Step 3: Add entry to SSH config ───
if grep -q "^Host $NAME$" "$CONFIG_FILE" 2>/dev/null; then
    echo "SSH config entry for '$NAME' already exists. Skipping."
else
    echo "Adding SSH config entry for '$NAME' ..."
    # Ensure config file exists and has a trailing newline
    touch "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    [[ -s "$CONFIG_FILE" ]] && [[ "$(tail -c 1 "$CONFIG_FILE")" != "" ]] && echo "" >> "$CONFIG_FILE"

    cat >> "$CONFIG_FILE" <<EOF

Host $NAME
    HostName $IP
    User $USER
    IdentityFile $KEY_FILE
    IdentitiesOnly yes
EOF
    echo "SSH config updated."
fi

# ─── Step 4: Create SCP helper alias ───
ALIAS_NAME="scp-$NAME"
ALIAS_LINE="alias $ALIAS_NAME='scp -F $CONFIG_FILE -r $NAME'"

if grep -q "alias $ALIAS_NAME=" "$SHELL_RC" 2>/dev/null; then
    echo "Alias '$ALIAS_NAME' already exists in $SHELL_RC. Skipping."
else
    echo "Adding alias '$ALIAS_NAME' to $SHELL_RC ..."
    touch "$SHELL_RC"
    cat >> "$SHELL_RC" <<EOF

# SCP shortcut for $NAME (added by ssh-setup.sh)
$ALIAS_LINE
EOF
    echo "Alias added."
fi

# ─── Done ───
echo ""
echo "══════════════════════════════════════════════"
echo "  Setup complete for '$NAME'"
echo "══════════════════════════════════════════════"
echo ""
echo "  SSH in:          ssh $NAME"
echo "  Copy TO remote:  scp-$NAME:/remote/path local_file"
echo "  Copy FROM remote: scp $NAME:/remote/path ./local/"
echo ""
echo "  Run 'source $SHELL_RC' or open a new terminal"
echo "  to activate the scp-$NAME alias."
echo ""
