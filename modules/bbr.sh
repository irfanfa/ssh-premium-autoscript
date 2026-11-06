#!/bin/bash
# ========================================================
# Modul Setup: TCP BBR & Kernel Network Optimization
# ========================================================

echo -e "\n\033[1;32m[*] Mengonfigurasi TCP BBR & Kernel Optimization...\033[0m"

# Tambahkan konfigurasi sysctl untuk BBR jika didukung
cat > /etc/sysctl.d/99-tunnel-optimize.conf << 'EOF'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.ip_forward = 1
EOF

# Terapkan sysctl tanpa menggagalkan script jika di dalam container/LXC
sysctl -p /etc/sysctl.d/99-tunnel-optimize.conf >/dev/null 2>&1 || sysctl --system >/dev/null 2>&1 || true

BBR_STATUS=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}' || echo "default")
echo -e "\033[1;32m[✓] Status Algoritma TCP: $BBR_STATUS\033[0m"
