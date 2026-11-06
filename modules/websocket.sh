#!/bin/bash
# ========================================================
# Modul Setup: Python WebSocket to SSH Proxy
# Menangani HTTP WebSocket (Port 80 & 8880)
# ========================================================

set -e

echo -e "\n\033[1;32m[*] Mengonfigurasi WebSocket Proxy (Port 80, 8880)...\033[0m"

# Pastikan python3 terpasang
apt-get install -y python3

# Salin script proxy ke direktori sistem
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/ws-proxy.py" /usr/local/bin/ws-proxy.py
chmod +x /usr/local/bin/ws-proxy.py

# 1. Systemd Service untuk Port 80
cat > /etc/systemd/system/ws-proxy.service << 'EOF'
[Unit]
Description=Python WebSocket to SSH Proxy Port 80
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/ws-proxy.py 80 109
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 2. Systemd Service untuk Port 8880 (Cloudflare CDN HTTP Alternative)
cat > /etc/systemd/system/ws-proxy-8880.service << 'EOF'
[Unit]
Description=Python WebSocket to SSH Proxy Port 8880
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/ws-proxy.py 8880 109
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Reload & Restart Service
systemctl daemon-reload
systemctl enable ws-proxy ws-proxy-8880
systemctl restart ws-proxy ws-proxy-8880

echo -e "\033[1;32m[✓] WebSocket Proxy (Port 80, 8880) berhasil diaktifkan!\033[0m"
