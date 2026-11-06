#!/bin/bash
# ========================================================
# Modul Setup: WebSocket Proxy Systemd Service
# ========================================================

set -e

echo -e "\n\033[1;32m[*] Mendaftarkan Layanan WebSocket Proxy ke Systemd...\033[0m"

# Pastikan Python3 terinstall
apt-get install -y python3

# Salin script proxy ke /usr/local/bin
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/ws-proxy.py" /usr/local/bin/ws-proxy.py
chmod +x /usr/local/bin/ws-proxy.py

# 1. Service Port 80 (Standard HTTP / Cloudflare CDN)
cat > /etc/systemd/system/ws-proxy.service << 'EOF'
[Unit]
Description=SSH WebSocket Proxy Port 80
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/ws-proxy.py 80
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 2. Service Port 8880 (Alternate HTTP Port Cloudflare CDN)
cat > /etc/systemd/system/ws-alt.service << 'EOF'
[Unit]
Description=SSH WebSocket Proxy Port 8880
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/ws-proxy.py 8880
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ws-proxy ws-alt
systemctl restart ws-proxy ws-alt

echo -e "\033[1;32m[✓] WebSocket Proxy (Port 80 & 8880) aktif!\033[0m"

