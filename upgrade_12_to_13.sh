#!/usr/bin/env bash
set -euo pipefail

# upgrade_12_to_13.sh
# Upgrade helper: Debian 12 (bookworm) -> Debian 13 (trixie)
# Usage: sudo ./upgrade_12_to_13.sh [--apply-upgrade] [--install-docker] [--install-vmware] [--yes]

OLD_NAME="bookworm"
NEW_NAME="trixie"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/root/upgrade-b${OLD_NAME}-to-${NEW_NAME}-${TIMESTAMP}"
ASSUME_YES=false
FORCE=false
APPLY_UPGRADE=false
DO_INSTALL_DOCKER=false
DO_INSTALL_VMWARE=false

# Check current Debian codename / version to avoid jumping versions
get_current_codename(){
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    if [[ -n "${VERSION_CODENAME:-}" ]]; then
      echo "$VERSION_CODENAME"; return 0
    fi
  fi
  if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -sc 2>/dev/null && return 0
  fi
  if [[ -r /etc/debian_version ]]; then
    ver=$(cut -d. -f1 /etc/debian_version)
    case "$ver" in
      10) echo "buster" ;;
      11) echo "bullseye" ;;
      12) echo "bookworm" ;;
      13) echo "trixie" ;;
      *) echo "unknown" ;;
    esac
    return 0
  fi
  echo "unknown"
}

CURRENT_CODENAME=$(get_current_codename)
# Minimal error helper (needed early, before full function definitions)
err(){ echo "[!] $*" >&2; }

usage(){
  cat <<'EOF'
Usage: sudo ./upgrade_12_to_13.sh [--apply-upgrade] [--install-docker] [--install-vmware] [--yes]
EOF
}

while [[ ${#} -gt 0 ]]; do
  case "$1" in
    --apply-upgrade) APPLY_UPGRADE=true; shift ;;
    --install-docker) DO_INSTALL_DOCKER=true; shift ;;
    --install-vmware) DO_INSTALL_VMWARE=true; shift ;;
    --yes|-y) ASSUME_YES=true; shift ;;
    --force) FORCE=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)" >&2; exit 2
fi

# Decide how to handle the current codename *after* parsing flags so we
# can react to --apply-upgrade, --yes and --force appropriately.
SKIP_SOURCE_CHANGE=false
AUTO_PROCEED_ON_SAME=false
if [[ "$CURRENT_CODENAME" == "$OLD_NAME" ]]; then
  : # expected, proceed normally
elif [[ "$CURRENT_CODENAME" == "$NEW_NAME" ]]; then
  SKIP_SOURCE_CHANGE=true
  # If user explicitly asked to apply changes, proceed with update/upgrade
  if $APPLY_UPGRADE || $FORCE || $ASSUME_YES; then
    echo "[!] System reports '$NEW_NAME' — will perform update/upgrade on ${NEW_NAME} (no sources changes)."
    AUTO_PROCEED_ON_SAME=true
  else
    # interactive confirm only (reading /dev/tty) — otherwise abort
    if [ -t 0 ] || [ -e /dev/tty ]; then
      if [ -e /dev/tty ]; then
        read -r -p "System already reports '$NEW_NAME'. Proceed to update/upgrade ${NEW_NAME} (no sources changes)? [y/N]: " ans </dev/tty
      else
        read -r -p "System already reports '$NEW_NAME'. Proceed to update/upgrade ${NEW_NAME} (no sources changes)? [y/N]: " ans
      fi
      case "$ans" in [Yy]|[Yy][Ee][Ss]) AUTO_PROCEED_ON_SAME=true ;; *) err "Aborting."; exit 4 ;; esac
    else
      err "System already reports '$NEW_NAME' and no interactive terminal is available. Use --force or --yes with --apply-upgrade to proceed non-interactively. Aborting."
      exit 4
    fi
  fi
else
  err "This script upgrades from '$OLD_NAME' to '$NEW_NAME' but system reports '$CURRENT_CODENAME'. Aborting to avoid unsupported jumps."
  exit 4
fi

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

log(){ echo "[+] $*"; }
err(){ echo "[!] $*" >&2; }
confirm(){
  if $ASSUME_YES; then return 0; fi
  # If stdin is a terminal, read from it. If not (e.g. when piping the script), try /dev/tty.
  if [ -t 0 ]; then
    read -r -p "$1 [y/N]: " ans
  else
    if [ -e /dev/tty ]; then
      read -r -p "$1 [y/N]: " ans </dev/tty
    else
      # No way to ask interactively; default to 'no'
      return 1
    fi
  fi
  case "$ans" in
    [Yy]|[Yy][Ee][Ss]) return 0 ;;
    *) return 1 ;;
  esac
}

log "Backup dir: $BACKUP_DIR"
log "Backing up /etc"
tar --absolute-names -czf "$BACKUP_DIR/etc-${TIMESTAMP}.tar.gz" /etc || err "backup /etc failed"
log "Saving package selections"
dpkg --get-selections '*' > "$BACKUP_DIR/packages-list.txt" || true

avail_kb=$(df --output=avail / | tail -1)
avail_gb=$((avail_kb/1024/1024))
log "Available on /: ${avail_kb} KB (${avail_gb} GB)"
if (( avail_gb < 4 )); then err "Less than 4GB free; free space before upgrading or proceed with caution."; if ! confirm "Continue anyway?"; then echo "Aborted."; exit 3; fi fi

if ! $APPLY_UPGRADE; then echo "Backups done. Re-run with --apply-upgrade to perform sources edit and upgrade."; exit 0; fi

if $SKIP_SOURCE_CHANGE; then
  if ! $AUTO_PROCEED_ON_SAME; then
    if ! confirm "Proceed to perform apt update && upgrade on ${NEW_NAME} (no sources will be changed)?"; then echo "Cancelled"; exit 0; fi
  else
    log "Auto-proceeding to perform apt update && upgrade on ${NEW_NAME} (no sources will be changed)"
  fi
else
  if ! confirm "Proceed to change apt sources from ${OLD_NAME} to ${NEW_NAME} and upgrade?"; then echo "Cancelled"; exit 0; fi
fi

cp -a /etc/apt/sources.list "$BACKUP_DIR/sources.list.bak"
cp -a /etc/apt/sources.list.d "$BACKUP_DIR/sources.list.d.bak" || true

if ! $SKIP_SOURCE_CHANGE; then
  log "Replacing '$OLD_NAME' with '$NEW_NAME' in apt sources"
  sed -i "s/${OLD_NAME}/${NEW_NAME}/g" /etc/apt/sources.list || true
  find /etc/apt/sources.list.d/ -type f -exec sed -i "s/${OLD_NAME}/${NEW_NAME}/g" {} \; || true
else
  log "Skipping apt sources changes because system already reports '$NEW_NAME'"
fi

log "Updating indexes"
# Normalize security repository entries which sometimes use 'suite/updates' format
log "Normalizing security repository entries (-> ${NEW_NAME}-security)"
sed -i "s|${NEW_NAME}/updates|${NEW_NAME}-security|g" /etc/apt/sources.list || true
find /etc/apt/sources.list.d/ -type f -exec sed -i "s|${NEW_NAME}/updates|${NEW_NAME}-security|g" {} \; || true

if $ASSUME_YES; then DEBIAN_FRONTEND=noninteractive apt update; else apt update; fi

log "Performing minimal upgrade (without new packages) using apt-get upgrade"
# Use apt-get upgrade for the minimal step (won't install new packages)
if $ASSUME_YES; then DEBIAN_FRONTEND=noninteractive apt-get upgrade -y; else apt-get upgrade; fi

log "Performing full upgrade to ${NEW_NAME}"
if $ASSUME_YES; then DEBIAN_FRONTEND=noninteractive apt full-upgrade -y; else apt full-upgrade; fi

log "Autoremove and clean"
apt --purge autoremove -y || true
apt autoclean || true

log "Upgrade step completed. Reboot recommended."
if confirm "Reboot now?"; then reboot; fi

if $DO_INSTALL_DOCKER; then
  log "Installing Docker (repo for ${NEW_NAME})"
  apt update
  apt install -y ca-certificates curl gnupg lsb-release apt-transport-https || true
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${NEW_NAME} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || err "docker install failed"
  systemctl enable --now docker || true
fi

if $DO_INSTALL_VMWARE; then
  apt update
  apt install -y sudo open-vm-tools || true
fi

log "All done. Backup dir: $BACKUP_DIR"
exit 0
