#!/bin/bash
# ========================================================
# Modul Setup: Stunnel (SSL / TLS Tunneling)
# ========================================================

set -e

echo -e "\n\033[1;32m[*] Mengonfigurasi Stunnel SSL/TLS...\033[0m"

apt-get install -y stunnel4 openssl

# 1. Generate SSL Self-Signed Certificate
mkdir -p /etc/stunnel
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=SSHPremium/OU=Network/CN=ssh-premium.tunnel" \
    -keyout /etc/stunnel/stunnel.pem \
    -out /etc/stunnel/stunnel.pem 2>/dev/null

chmod 600 /etc/stunnel/stunnel.pem

# 2. Buat konfigurasi Stunnel (Port 443 & 777 meneruskan ke Dropbear 109)
cat > /etc/stunnel/stunnel.conf << 'EOF'
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear-ssl]
accept = 443
connect = 127.0.0.1:109

[dropbear-alt-ssl]
accept = 777
connect = 127.0.0.1:109
EOF

# 3. Aktifkan service Stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4 2>/dev/null || true

systemctl enable stunnel4
systemctl restart stunnel4

echo -e "\033[1;32m[✓] Stunnel (SSL Port 443, 777) berhasil dikonfigurasi!\033[0m"
