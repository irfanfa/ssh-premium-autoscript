#!/bin/bash
# ========================================================
# Modul Setup: TCP BBR & Kernel Network Optimization
# ========================================================

set -e

echo -e "\n\033[1;32m[*] Mengaktifkan TCP BBR & Optimasi Jaringan Kernel...\033[0m"

# Tambahkan konfigurasi sysctl untuk BBR dan optimasi TCP
cat > /etc/sysctl.d/99-tunnel-optimize.conf << 'EOF'
# Aktifkan BBR Congestion Control
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# Optimasi Buffer Jaringan & Socket
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.netdev_max_backlog = 10000
net.core.somaxconn = 4096

# Optimasi TCP Connection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.ip_forward = 1
EOF

# Terapkan konfigurasi kernel
sysctl -p /etc/sysctl.d/99-tunnel-optimize.conf >/dev/null 2>&1 || sysctl --system >/dev/null 2>&1

# Verifikasi apakah BBR aktif
BBR_STATUS=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
if [ "$BBR_STATUS" == "bbr" ]; then
    echo -e "\033[1;32m[✓] TCP BBR berhasil aktif! ($BBR_STATUS)\033[0m"
else
    echo -e "\033[1;33m[!] BBR belum aktif di kernel ini (Status: $BBR_STATUS), menggunakan default.\033[0m"
fi

