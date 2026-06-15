Script

```
#!/usr/bin/env bash
set -euo pipefail

IFACE="awg0"
RUN_USER="lab"
CONF_DIR="/etc/amnezia/amneziawg"
CONF_FILE="$CONF_DIR/$IFACE.conf"

if modinfo amneziawg >/dev/null 2>&1 \
   && command -v awg >/dev/null 2>&1 \
   && command -v awg-quick >/dev/null 2>&1; then
    echo "AmneziaWG already installed. Skipping install."
    sudo modprobe amneziawg || true
else
    echo "Installing AmneziaWG..."

    sudo apt update
    sudo apt install -y \
      git build-essential make gcc dkms acl \
      linux-headers-"$(uname -r)" \
      resolvconf iproute2

    WORKDIR="$(mktemp -d)"
    cd "$WORKDIR"

    git clone https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git
    cd amneziawg-linux-kernel-module/src
    make
    sudo make install
    sudo modprobe amneziawg

    cd "$WORKDIR"
    git clone https://github.com/amnezia-vpn/amneziawg-tools.git
    cd amneziawg-tools/src
    make
    sudo make install

    cd /
    rm -rf "$WORKDIR"
fi

# Права на /etc/amnezia для lab
sudo apt install -y acl >/dev/null 2>&1 || true

sudo groupadd -f amnezia
sudo usermod -aG amnezia "$RUN_USER"

sudo mkdir -p /etc/amnezia
sudo chgrp -R amnezia /etc/amnezia
sudo chmod -R 2775 /etc/amnezia

sudo setfacl -R -m "u:$RUN_USER:rwx" /etc/amnezia
sudo setfacl -R -d -m "u:$RUN_USER:rwx" /etc/amnezia

# sudo без пароля для AWG-команд
AWG_QUICK_PATH="$(command -v awg-quick)"
AWG_PATH="$(command -v awg)"
SYSTEMCTL_PATH="$(command -v systemctl)"

sudo tee /etc/sudoers.d/lab-amneziawg >/dev/null <<EOF
$RUN_USER ALL=(ALL) NOPASSWD: $AWG_QUICK_PATH, $AWG_PATH, $SYSTEMCTL_PATH
EOF

sudo chmod 440 /etc/sudoers.d/lab-amneziawg

# Начиная отсюда работа с конфигом без sudo
mkdir -p "$CONF_DIR"

cat > "$CONF_FILE" <<'EOF'
# peer907
[Interface]
Address = 10.7.3.250/32
PrivateKey = +HwrJk5caxpIKPBw+yC01veT2d5zsNjSMf7BfVf/X2Y=
DNS = 8.8.8.8

Jc = 1
Jmin = 50
Jmax = 1000
S1 = 15
S2 = 101
H1 = 5
H2 = 2147484
H3 = 214748364
H4 = 2147483647

## PASTE PEER SECTION
EOF

chmod 600 "$CONF_FILE"

sudo -n awg-quick down "$CONF_FILE" 2>/dev/null || true
sudo -n awg-quick up "$CONF_FILE"

sudo -n systemctl enable "awg-quick@$IFACE" || true

echo
echo "OK. AWG is up."
sudo -n awg show
```
