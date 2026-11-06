#!/bin/bash
# ========================================================
# Script: Auto-Delete Expired Accounts (user-xp)
# Dijalankan via Cron Job setiap tengah malam (00:00)
# ========================================================

NOW=$(date +%s)
DB_FILE="/etc/ssh-users.db"
TEMP_FILE="/tmp/ssh-users.tmp"

if [ ! -f "$DB_FILE" ]; then
    touch "$DB_FILE"
    exit 0
fi

> "$TEMP_FILE"

while IFS=: read -r USERNAME EXP_DATE; do
    if [ -z "$USERNAME" ] || [ -z "$EXP_DATE" ]; then
        continue
    fi

    # Konversi tanggal exp ke Unix Epoch
    EXP_EPOCH=$(date -d "$EXP_DATE" +%s 2>/dev/null || echo 0)

    if [ "$NOW" -ge "$EXP_EPOCH" ]; then
        echo "[*] Akun kadaluarsa terdeteksi: $USERNAME ($EXP_DATE). Menghapus..."
        
        # Kill session yang sedang aktif jika ada
        pkill -u "$USERNAME" 2>/dev/null || true
        
        # Hapus user dari sistem Linux
        userdel -f "$USERNAME" 2>/dev/null || true
    else
        # Simpan kembali jika masih aktif
        echo "$USERNAME:$EXP_DATE" >> "$TEMP_FILE"
    fi
done < "$DB_FILE"

mv "$TEMP_FILE" "$DB_FILE"
chmod 600 "$DB_FILE"
