#!/bin/bash
# ========================================================
# Auto-Installer Script: SSH & WebSocket Premium Server
# Tahan error & kompatibel dengan KVM, OpenVZ, LXC, Container
# ========================================================

# Jangan gunakan set -e agar jika ada modul opsional (seperti BBR di container)
# yang gagal, installer tetap lanjut sampai selesai memasang menu & core services.

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
    echo -e "${RED}[!] Skrip ini wajib dijalankan sebagai user ROOT (ketik: sudo su)${NC}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Pasang Perintah CLI MENU TERLEBIH DAHULU (Prioritas Utama)
echo -e "${GREEN}[*] Memasang CLI Menu & Script Manajemen User...${NC}"
cp -f "$SCRIPT_DIR/bin/menu.sh" /usr/local/bin/menu 2>/dev/null || true
cp -f "$SCRIPT_DIR/bin/menu.sh" /usr/bin/menu 2>/dev/null || true
cp -f "$SCRIPT_DIR/bin/user-add.sh" /usr/local/bin/user-add 2>/dev/null || true
cp -f "$SCRIPT_DIR/bin/user-add.sh" /usr/bin/user-add 2>/dev/null || true
cp -f "$SCRIPT_DIR/bin/user-xp.sh" /usr/local/bin/user-xp 2>/dev/null || true
cp -f "$SCRIPT_DIR/bin/user-lock.sh" /usr/local/bin/user-lock 2>/dev/null || true

chmod +x /usr/local/bin/menu /usr/bin/menu /usr/local/bin/user-add /usr/bin/user-add /usr/local/bin/user-xp /usr/local/bin/user-lock 2>/dev/null || true
touch /etc/ssh-users.db
chmod 600 /etc/ssh-users.db

# 3. Setup Domain
PUB_IP=$(curl -s4 ifconfig.me || curl -s4 icanhazip.com || echo "YOUR-SERVER-IP")
echo -e "\n${YELLOW}[?] Masukkan Domain / Bug Host (Contoh: sg1.domainmu.com)${NC}"
read -t 15 -p "    Tekan ENTER (atau tunggu 15 dtk) untuk gunakan IP ($PUB_IP): " INPUT_DOMAIN || true

if [ -z "$INPUT_DOMAIN" ]; then
    DOMAIN="$PUB_IP"
else
    DOMAIN="$INPUT_DOMAIN"
fi
echo "$DOMAIN" > /etc/vps-domain
echo -e "\n${GREEN}[✓] Host terdaftar: $DOMAIN${NC}\n"

# 4. Update Repository & Install Dependensi Dasar
echo -e "${GREEN}[*] Memperbarui paket sistem...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y || true
apt-get install -y curl wget git cron ufw iptables net-tools screen lsof socat python3 openssl dropbear stunnel4 || true

# Berikan izin eksekusi seluruh modul
chmod +x "$SCRIPT_DIR"/modules/*.sh "$SCRIPT_DIR"/modules/*.py 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/bin/*.sh 2>/dev/null || true

# 5. Eksekusi Modul Pemasangan (Toleran terhadap Container/LXC)
echo -e "\n${GREEN}[*] Menjalankan modul-modul instalasi...${NC}"

# Modul BBR
bash "$SCRIPT_DIR/modules/bbr.sh" || echo -e "${YELLOW}[!] BBR dilewati (lingkungan container).${NC}"

# Modul OpenSSH & Dropbear
bash "$SCRIPT_DIR/modules/ssh-dropbear.sh" || echo -e "${RED}[!] Gagal pada modul Dropbear.${NC}"

# Modul Stunnel SSL
bash "$SCRIPT_DIR/modules/stunnel.sh" || echo -e "${RED}[!] Gagal pada modul Stunnel.${NC}"

# Modul WebSocket Proxy
bash "$SCRIPT_DIR/modules/ws-service.sh" || echo -e "${RED}[!] Gagal pada modul WebSocket.${NC}"

# Modul BadVPN (Opsional untuk game)
bash "$SCRIPT_DIR/modules/badvpn.sh" || echo -e "${YELLOW}[!] BadVPN dilewati.${NC}"

# 6. Konfigurasi Cron Job Otomatis
echo -e "\n${GREEN}[*] Mengatur Cron Job harian...${NC}"
CRON_FILE="/etc/cron.d/ssh-premium"
cat > "$CRON_FILE" << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 0 * * * root /usr/local/bin/user-xp >/dev/null 2>&1
*/15 * * * * root /usr/local/bin/user-lock >/dev/null 2>&1
EOF
chmod 644 "$CRON_FILE"
systemctl restart cron 2>/dev/null || service cron restart 2>/dev/null || true

# 7. Konfigurasi Firewall Port (jika ufw terpasang)
if command -v ufw &>/dev/null; then
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
fi

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
echo -e " Ketik ${CYAN}menu${NC} di terminal untuk membuka dashboard!"
echo -e "${GREEN}====================================================${NC}"
