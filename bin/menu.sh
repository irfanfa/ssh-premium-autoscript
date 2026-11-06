#!/bin/bash
# ========================================================
# Script: CLI Management Dashboard (menu)
# ========================================================

clear
PUB_IP=$(curl -s4 ifconfig.me || curl -s4 icanhazip.com || echo "N/A")
TOTAL_USERS=$(wc -l < /etc/ssh-users.db 2>/dev/null || echo 0)

# Cek status service
STATUS_SSH=$(systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || echo "dead")
STATUS_DROPBEAR=$(systemctl is-active dropbear 2>/dev/null || echo "dead")
STATUS_STUNNEL=$(systemctl is-active stunnel4 2>/dev/null || echo "dead")
STATUS_WS=$(systemctl is-active ws-proxy 2>/dev/null || echo "dead")
STATUS_BADVPN=$(systemctl is-active badvpn-7100 2>/dev/null || echo "dead")

echo -e "\033[1;36m====================================================\033[0m"
echo -e "\033[1;33m             SSH PREMIUM SERVER MANAGER             \033[0m"
echo -e "\033[1;36m====================================================\033[0m"
echo -e " Server IP    : \033[1;37m$PUB_IP\033[0m"
echo -e " Total Akun   : \033[1;32m$TOTAL_USERS User\033[0m"
echo -e " OS           : \033[1;37m$(grep -oP '(?<=PRETTY_NAME=")[^"]*' /etc/os-release 2>/dev/null || uname -s)\033[0m"
echo -e "----------------------------------------------------"
echo -e " Status Layanan:"
echo -e " - OpenSSH : $STATUS_SSH | Dropbear : $STATUS_DROPBEAR"
echo -e " - Stunnel : $STATUS_STUNNEL | WebSocket: $STATUS_WS | BadVPN: $STATUS_BADVPN"
echo -e "\033[1;36m====================================================\033[0m"
echo -e " \033[1;32m[1]\033[0m Buat Akun SSH Premium Baru"
echo -e " \033[1;32m[2]\033[0m Hapus Akun SSH"
echo -e " \033[1;32m[3]\033[0m Cek Pengguna Login / Online"
echo -e " \033[1;32m[4]\033[0m Daftar Semua Akun & Masa Aktif"
echo -e " \033[1;32m[5]\033[0m Restart Semua Layanan Tunnel"
echo -e " \033[1;31m[0]\033[0m Keluar"
echo -e "\033[1;36m====================================================\033[0m"
read -p " Pilih Menu [0-5]: " OPTION

case $OPTION in
    1)
        /usr/local/bin/user-add
        ;;
    2)
        read -p "Masukkan Username yang ingin dihapus: " DEL_USER
        if id "$DEL_USER" &>/dev/null; then
            pkill -u "$DEL_USER" 2>/dev/null || true
            userdel -f "$DEL_USER"
            sed -i "/^$DEL_USER:/d" /etc/ssh-users.db 2>/dev/null || true
            echo -e "\033[1;32m[✓] User '$DEL_USER' berhasil dihapus!\033[0m"
        else
            echo -e "\033[1;31m[!] User '$DEL_USER' tidak ditemukan!\033[0m"
        fi
        ;;
    3)
        echo -e "\n\033[1;33m--- Pengguna SSH / Dropbear yang Sedang Aktif ---\033[0m"
        who
        echo -e "\n\033[1;33m--- Dropbear Active Processes ---\033[0m"
        ps aux | grep -i dropbear | grep -v grep | awk '{print $1, $2, $11}'
        ;;
    4)
        echo -e "\n\033[1;33m--- Daftar Akun SSH Premium & Masa Aktif ---\033[0m"
        if [ -f "/etc/ssh-users.db" ] && [ -s "/etc/ssh-users.db" ]; then
            printf "%-20s %-15s\n" "USERNAME" "EXPIRY DATE"
            echo "-------------------------------------"
            while IFS=: read -r U EXP; do
                printf "%-20s %-15s\n" "$U" "$EXP"
            done < /etc/ssh-users.db
        else
            echo "Belum ada user yang dibuat."
        fi
        ;;
    5)
        echo -e "\n[*] Merestart seluruh service..."
        systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
        systemctl restart dropbear
        systemctl restart stunnel4
        systemctl restart ws-proxy
        systemctl restart badvpn-7100 badvpn-7200
        echo -e "\033[1;32m[✓] Seluruh service berhasil direstart!\033[0m"
        ;;
    0)
        exit 0
        ;;
    *)
        echo -e "\033[1;31m[!] Pilihan tidak valid!\033[0m"
        ;;
esac
