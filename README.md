Script

```
#!/usr/bin/env bash
set -euo pipefail

IFACE="awg0"
CONF_DIR="/etc/amnezia/amneziawg"
CONF_FILE="$CONF_DIR/$IFACE.conf"

sudo apt update
sudo apt install -y \
  git build-essential make gcc dkms \
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

sudo mkdir -p "$CONF_DIR"

sudo tee "$CONF_FILE" >/dev/null <<'EOF'
# country: ru
[Interface]
Address = 10.10.0.XXX/32
PrivateKey = XXX
DNS = 8.8.8.8
Jc = 12
Jmin = 8
Jmax = 80
S1 = 15
S2 = 150
H1 = 214748
H2 = 2147484
H3 = 214748364
H4 = 2147483647

[Peer]
PublicKey = XXX
PresharedKey = XXX
Endpoint = XXX:30921
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

sudo chmod 600 "$CONF_FILE"

sudo awg-quick down "$CONF_FILE" 2>/dev/null || true
sudo awg-quick up "$CONF_FILE"

sudo systemctl enable "awg-quick@$IFACE" || true

echo
echo "OK. AWG is up."
sudo awg show
```
