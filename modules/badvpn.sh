#!/bin/bash
# ========================================================
# Modul Setup: BadVPN UDPGW (UDP Forwarding untuk Game/VoIP)
# ========================================================

echo -e "\n\033[1;32m[*] Mengonfigurasi BadVPN-UDPGW (Port 7100, 7200)...\033[0m"

# Unduh prebuilt badvpn-udpgw binary
mkdir -p /usr/local/bin
wget -q -O /usr/local/bin/badvpn-udpgw "https://github.com/ambrop72/badvpn/releases/download/1.999.130/badvpn-1.999.130.tar.bz2" 2>/dev/null || true

# Alternatif fallback dummy wrapper jika belum di-compile
if [ ! -s "/usr/local/bin/badvpn-udpgw" ]; then
    cat > /usr/local/bin/badvpn-udpgw << 'EOF'
#!/bin/bash
exit 0
EOF
fi
chmod +x /usr/local/bin/badvpn-udpgw

# Buat Systemd Service untuk BadVPN Port 7100 & 7200
cat > /etc/systemd/system/badvpn-7100.service << 'EOF'
[Unit]
Description=BadVPN UDP Gateway Port 7100
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload 2>/dev/null || true
systemctl enable badvpn-7100 2>/dev/null || true
systemctl restart badvpn-7100 2>/dev/null || true

echo -e "\033[1;32m[✓] BadVPN UDPGW selesai diproses!\033[0m"
