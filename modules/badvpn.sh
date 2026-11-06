#!/bin/bash
# ========================================================
# Modul Setup: BadVPN UDPGW (UDP Forwarding untuk Game/VoIP)
# ========================================================

set -e

echo -e "\n\033[1;32m[*] Mengonfigurasi BadVPN-UDPGW (Port 7100, 7200, 7300)...\033[0m"

# Unduh binary badvpn-udpgw atau compile jika belum ada
if [ ! -f "/usr/local/bin/badvpn-udpgw" ]; then
    echo "[*] Mendownload badvpn-udpgw binary..."
    wget -q -O /usr/local/bin/badvpn-udpgw "https://raw.githubusercontent.com/ambrop72/badvpn/master/udpgw/udpgw.c" 2>/dev/null || true
    
    # Alternatif build jika download langsung tidak tersedia
    apt-get install -y cmake git build-essential
    cd /tmp
    rm -rf badvpn
    git clone --depth 1 https://github.com/ambrop72/badvpn.git
    cd badvpn
    mkdir -p build && cd build
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
    make install
    cp udpgw/badvpn-udpgw /usr/local/bin/badvpn-udpgw
    cd /
    rm -rf /tmp/badvpn
fi

chmod +x /usr/local/bin/badvpn-udpgw

# Buat Systemd Service untuk BadVPN Port 7100
cat > /etc/systemd/system/badvpn-7100.service << 'EOF'
[Unit]
Description=BadVPN UDP Gateway Port 7100
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500 --max-connections-for-client 8
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Buat Systemd Service untuk BadVPN Port 7200
cat > /etc/systemd/system/badvpn-7200.service << 'EOF'
[Unit]
Description=BadVPN UDP Gateway Port 7200
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500 --max-connections-for-client 8
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable badvpn-7100 badvpn-7200
systemctl restart badvpn-7100 badvpn-7200

echo -e "\033[1;32m[✓] BadVPN UDPGW (7100, 7200) aktif!\033[0m"
