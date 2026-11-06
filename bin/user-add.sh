#!/bin/bash
# ========================================================
# Script: Pembuatan Akun SSH Premium (user-add)
# ========================================================

clear
echo -e "\033[1;36m============================================\033[0m"
echo -e "\033[1;33m          CREATE SSH PREMIUM ACCOUNT        \033[0m"
echo -e "\033[1;36m============================================\033[0m"

# Dapatkan IP Publik VPS
PUB_IP=$(curl -s4 ifconfig.me || curl -s4 icanhazip.com || echo "YOUR-SERVER-IP")
DOMAIN=$(cat /etc/vps-domain 2>/dev/null || echo "$PUB_IP")

read -p "Masukkan Username : " USERNAME
if [ -z "$USERNAME" ]; then
    echo -e "\033[1;31m[!] Username tidak boleh kosong!\033[0m"
    exit 1
fi

# Cek apakah username sudah ada
if id "$USERNAME" &>/dev/null; then
    echo -e "\033[1;31m[!] Username '$USERNAME' sudah terdaftar! Gunakan nama lain.\033[0m"
    exit 1
fi

read -p "Masukkan Password : " PASSWORD
if [ -z "$PASSWORD" ]; then
    echo -e "\033[1;31m[!] Password tidak boleh kosong!\033[0m"
    exit 1
fi

read -p "Masa Aktif (Hari) : " DAYS
if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
    echo -e "\033[1;31m[!] Hari harus berupa angka!\033[0m"
    exit 1
fi

# Hitung tanggal kadaluarsa (YYYY-MM-DD)
EXP_DATE=$(date -d "+${DAYS} days" +"%Y-%m-%d")
DISPLAY_EXP=$(date -d "+${DAYS} days" +"%d %b %Y")

# Buat User Linux tanpa Shell Command (/bin/false)
useradd -e "$EXP_DATE" -s /bin/false -M "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

# Simpan metadata ke database lokal
echo "$USERNAME:$EXP_DATE" >> /etc/ssh-users.db

clear
echo -e "\033[1;32m============================================\033[0m"
echo -e "\033[1;32m       SSH PREMIUM BERHASIL DIBUAT          \033[0m"
echo -e "\033[1;32m============================================\033[0m"
echo -e " Host / IP       : \033[1;33m$DOMAIN\033[0m"
echo -e " IP VPS Asli     : $PUB_IP"
echo -e " Username        : \033[1;36m$USERNAME\033[0m"
echo -e " Password        : \033[1;36m$PASSWORD\033[0m"
echo -e "--------------------------------------------"
echo -e " OpenSSH Port    : 22, 2253"
echo -e " Dropbear Port   : 109, 143"
echo -e " SSL / Stunnel   : 443, 777"
echo -e " WebSocket (WS)  : 80, 8880"
echo -e " BadVPN UDPGW    : 7100, 7200"
echo -e "--------------------------------------------"
echo -e " Masa Aktif      : $DAYS Hari"
echo -e " Kadaluarsa Pada : \033[1;31m$DISPLAY_EXP\033[0m"
echo -e "============================================\033[0m"
echo -e " Contoh Payload WS HTTP:"
echo -e " \033[0;37mGET / HTTP/1.1[crlf]Host: $DOMAIN[crlf]Upgrade: websocket[crlf][crlf]\033[0m"
echo -e "============================================\033[0m"
