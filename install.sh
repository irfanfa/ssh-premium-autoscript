#!/bin/bash
# ========================================================
# Auto-Installer Script: SSH & WebSocket Premium Server
# Mendukung: Ubuntu 20.04 / 22.04 / 24.04 & Debian 10 / 11 / 12
# ========================================================

set -e

# Warna output terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}   AUTO-INSTALLER SERVER SSH & WEBSOCKET PREMIUM    ${NC}"
echo -e "${CYAN}====================================================${NC}"

# 1. Pastikan dijalankan sebagai ROOT
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Skrip ini wajib dijalankan sebagai user ROOT!${NC}"
    exit 1
fi

# 2. Deteksi OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_ID
else
    echo -e "${RED}[!] Sistem operasi tidak dikenali.${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Sistem terdeteksi: $OS_NAME $OS_VERSION${NC}"

# 3. Setup Domain (Opsional, untuk Cloudflare CDN)
PUB_IP=$(curl -s4 ifconfig.me || curl -s4 icanhazip.com || echo "")
echo -e "\n${YELLOW}[?] Masukkan Domain / Bug Host (Contoh: sg1.domainmu.com)${NC}"
read -p "    Jika tidak punya, tekan ENTER untuk menggunakan IP VPS ($PUB_IP): " INPUT_DOMAIN

if [ -z "$INPUT_DOMAIN" ]; then
    DOMAIN="$PUB_IP"
else
    DOMAIN="$INPUT_DOMAIN"
fi
echo "$DOMAIN" > /etc/vps-domain
echo -e "${GREEN}[✓] Domain tersimpan: $DOMAIN${NC}\n"

# 4. Update Repository & Install Dependensi Dasar
echo -e "${GREEN}[*] Memperbarui repository dan menginstal dependensi...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl wget git cron ufw iptables net-tools screen lsof socat python3 openssl

# 5. Eksekusi Modul Pemasangan
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Berikan izin eksekusi seluruh modul & bin
chmod +x "$SCRIPT_DIR"/modules/*.sh "$SCRIPT_DIR"/modules/*.py 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/bin/*.sh 2>/dev/null || true

# Jalankan modul-modul
bash "$SCRIPT_DIR/modules/bbr.sh"
bash "$SCRIPT_DIR/modules/ssh-dropbear.sh"
bash "$SCRIPT_DIR/modules/stunnel.sh"
bash "$SCRIPT_DIR/modules/ws-service.sh"
bash "$SCRIPT_DIR/modules/badvpn.sh"

# 6. Pasang Perintah CLI ke /usr/local/bin
echo -e "\n${GREEN}[*] Mengonfigurasi CLI Menu & Otomasi Manajemen User...${NC}"
cp "$SCRIPT_DIR/bin/menu.sh" /usr/local/bin/menu
cp "$SCRIPT_DIR/bin/user-add.sh" /usr/local/bin/user-add
cp "$SCRIPT_DIR/bin/user-xp.sh" /usr/local/bin/user-xp
cp "$SCRIPT_DIR/bin/user-lock.sh" /usr/local/bin/user-lock

chmod +x /usr/local/bin/menu /usr/local/bin/user-add /usr/local/bin/user-xp /usr/local/bin/user-lock

# Inisialisasi Database User jika belum ada
touch /etc/ssh-users.db
chmod 600 /etc/ssh-users.db

# 7. Konfigurasi Cron Job Otomatis
echo -e "${GREEN}[*] Mengatur Cron Job harian (Auto-Expired & Multi-Login check)...${NC}"
CRON_FILE="/etc/cron.d/ssh-premium"
cat > "$CRON_FILE" << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Hapus user expired setiap pukul 00:00 tengah malam
0 0 * * * root /usr/local/bin/user-xp >/dev/null 2>&1

# Periksa multi-login setiap 15 menit
*/15 * * * * root /usr/local/bin/user-lock >/dev/null 2>&1
EOF
chmod 644 "$CRON_FILE"
systemctl restart cron 2>/dev/null || systemctl restart crond 2>/dev/null || true

# 8. Konfigurasi Firewall (UFW)
echo -e "${GREEN}[*] Mengonfigurasi Firewall Ports...${NC}"
ufw allow 22/tcp >/dev/null 2>&1 || true
ufw allow 2253/tcp >/dev/null 2>&1 || true
ufw allow 109/tcp >/dev/null 2>&1 || true
ufw allow 143/tcp >/dev/null 2>&1 || true
ufw allow 80/tcp >/dev/null 2>&1 || true
ufw allow 8880/tcp >/dev/null 2>&1 || true
ufw allow 443/tcp >/dev/null 2>&1 || true
ufw allow 777/tcp >/dev/null 2>&1 || true
ufw allow 7100/tcp >/dev/null 2>&1 || true
ufw allow 7200/tcp >/dev/null 2>&1 || true

clear
echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}     INSTALASI SERVER SSH PREMIUM SELESAI!          ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e " Host / Domain      : ${YELLOW}$DOMAIN${NC}"
echo -e " IP Asli Server     : $PUB_IP"
echo -e "----------------------------------------------------"
echo -e " OpenSSH Port       : 22, 2253"
echo -e " Dropbear Port      : 109, 143"
echo -e " Stunnel (SSL/TLS)  : 443, 777"
echo -e " WebSocket HTTP     : 80, 8880"
echo -e " BadVPN UDPGW       : 7100, 7200"
echo -e "----------------------------------------------------"
echo -e " Fitur Otomasi:"
echo -e " - Auto-Delete Expired Accounts (Tiap 00:00)"
echo -e " - Anti Multi-Login Killer (Tiap 15 Menit)"
echo -e " - TCP BBR Network Speed Accelerator (Aktif)"
echo -e "----------------------------------------------------"
echo -e " Ketik ${CYAN}menu${NC} di terminal VPS Anda kapan saja untuk"
echo -e " mengelola pengguna dan memantau status server!"
echo -e "${GREEN}====================================================${NC}"

