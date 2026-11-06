#!/bin/bash
# ========================================================
# Modul Setup: OpenSSH & Dropbear
# ========================================================

set -e

echo -e "\n\033[1;32m[*] Mengonfigurasi OpenSSH & Dropbear...\033[0m"

# Pastikan /bin/false terdaftar di /etc/shells agar tunneling diizinkan tanpa shell command
if ! grep -q "^/bin/false" /etc/shells; then
    echo "/bin/false" >> /etc/shells
fi

# 1. Konfigurasi OpenSSH
cat > /etc/ssh/sshd_config.d/premium-ssh.conf << 'EOF'
Port 22
Port 2253
PermitRootLogin yes
PasswordAuthentication yes
X11Forwarding no
Banner /etc/issue.net
MaxAuthTries 5
ClientAliveInterval 30
ClientAliveCountMax 3
EOF

systemctl restart ssh || systemctl restart sshd

# 2. Install & Konfigurasi Dropbear
apt-get install -y dropbear

cat > /etc/default/dropbear << 'EOF'
NO_START=0
DROPBEAR_PORT=143
DROPBEAR_EXTRA_ARGS="-p 109"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
EOF

# 3. Banner SSH Premium Default
cat > /etc/issue.net << 'EOF'
<font color="cyan"><b>=====================================</b></font><br>
<font color="yellow"><b>   PREMIUM SSH & WEBSOCKET SERVER   </b></font><br>
<font color="cyan"><b>=====================================</b></font><br>
<font color="red"><b> PERATURAN SERVER:                  </b></font><br>
<font color="white"> - DILARANG SPAM / DDOS / CARDING   </font><br>
<font color="white"> - DILARANG MULTI-LOGIN BERLEBIHAN  </font><br>
<font color="white"> - PATUHI ATURAN TOS PENYEDIA VPS   </font><br>
<font color="cyan"><b>=====================================</b></font>
EOF

systemctl daemon-reload
systemctl enable dropbear
systemctl restart dropbear

echo -e "\033[1;32m[✓] OpenSSH (22, 2253) & Dropbear (109, 143) berhasil dikonfigurasi!\033[0m"
