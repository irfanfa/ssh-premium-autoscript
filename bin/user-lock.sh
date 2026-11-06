#!/bin/bash
# ========================================================
# Script: Anti Multi-Login Checker (user-lock)
# Membatasi jumlah sesi bersamaan (Default: Max 2 Login)
# ========================================================

MAX_LOGIN=2
LOG_FILE="/var/log/ssh-multilogin.log"
DB_FILE="/etc/ssh-users.db"

if [ ! -f "$DB_FILE" ]; then
    exit 0
fi

while IFS=: read -r USERNAME EXP; do
    if [ -z "$USERNAME" ]; then
        continue
    fi

    # Hitung jumlah sesi aktif untuk user ini (Dropbear + OpenSSH)
    DROPBEAR_COUNT=$(ps aux | grep -i "dropbear" | grep "$USERNAME" | grep -v grep | wc -l)
    SSHD_COUNT=$(ps aux | grep -i "sshd:" | grep "$USERNAME" | grep -v grep | wc -l)
    TOTAL_SESSIONS=$((DROPBEAR_COUNT + SSHD_COUNT))

    if [ "$TOTAL_SESSIONS" -gt "$MAX_LOGIN" ]; then
        DATE_NOW=$(date +"%Y-%m-%d %H:%M:%S")
        echo "[$DATE_NOW] Multi-login terdeteksi: $USERNAME ($TOTAL_SESSIONS sesi > max $MAX_LOGIN). Memutus sesi..." >> "$LOG_FILE"
        
        # Putus semua sesi user yang melanggar
        pkill -u "$USERNAME" 2>/dev/null || true
    fi
done < "$DB_FILE"

