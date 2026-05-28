#!/usr/bin/env bash
set -euo pipefail

IFACE="awg0"
CONF="/etc/amnezia/amneziawg/${IFACE}.conf"

usage() {
  echo "Usage: $0 {up|down|restart|status}"
  exit 1
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
  fi
}

cmd_up() {
  echo "[*] Starting ${IFACE}..."
  awg-quick up "$CONF"
  echo
  awg show
}

cmd_down() {
  echo "[*] Stopping ${IFACE}..."
  awg-quick down "$CONF"
}

cmd_restart() {
  echo "[*] Restarting ${IFACE}..."
  awg-quick down "$CONF" 2>/dev/null || true
  awg-quick up "$CONF"
  echo
  awg show
}

cmd_status() {
  echo "[*] Status ${IFACE}:"
  echo
  awg show || true
  echo
  ip addr show "$IFACE" || true
}

[[ $# -ne 1 ]] && usage

require_root "$@"

case "$1" in
  up)
    cmd_up
    ;;
  down)
    cmd_down
    ;;
  restart)
    cmd_restart
    ;;
  status)
    cmd_status
    ;;
  *)
    usage
    ;;
esac
