# SSH & WebSocket Premium Auto-Installer Script

Project auto-installer modular untuk membangun server **SSH Premium, SSL/TLS, WebSocket CDN, dan UDP Gateway (BadVPN)** di VPS Linux (Ubuntu / Debian).

---

## 🚀 Fitur Utama

- **Multi-Port OpenSSH & Dropbear**: Port `22`, `2253`, `109`, `143`.
- **SSL / TLS Tunneling (Stunnel5)**: Port `443` & `777`.
- **SSH over WebSocket (Cloudflare CDN Ready)**: Port `80` & `8880`.
- **BadVPN UDPGW**: Port `7100` & `7200` (Mendukung game online & voice call lewat SSH tunnel).
- **TCP BBR Accelerator**: Optimasi throughput jaringan kernel Linux.
- **Sistem Manajemen User Aman**: Akun tidak memiliki akses bash shell (`/bin/false`).
- **Otomasi Terjadwal (Cron)**:
  - Otomatis menghapus akun yang kadaluarsa setiap pukul 00:00 tengah malam.
  - Memutus koneksi otomatis jika ada user yang melanggar batas multi-login.
- **CLI Dashboard (`menu`)**: Antarmuka terminal interaktif untuk buat akun, hapus akun, cek status online, dan cek masa aktif.

---

## 📁 Struktur Direktori

```text
ssh-premium-autoscript/
├── install.sh                  # Installer utama (entrypoint)
├── modules/
│   ├── bbr.sh                  # Aktivasi TCP BBR & tuning buffer jaringan
│   ├── ssh-dropbear.sh         # Konfigurasi OpenSSH & Dropbear
│   ├── stunnel.sh              # Konfigurasi Stunnel SSL/TLS
│   ├── ws-proxy.py             # Daemon Python WebSocket ke Dropbear
│   ├── ws-service.sh           # Konfigurasi systemd WebSocket Proxy
│   └── badvpn.sh               # UDP Gateway untuk gaming & VoIP
├── bin/
│   ├── menu.sh                 # Dashboard CLI (`menu`)
│   ├── user-add.sh             # Skrip pembuatan user & masa aktif
│   ├── user-xp.sh              # Skrip penghapusan user kadaluarsa
│   └── user-lock.sh            # Skrip proteksi batas multi-login
└── README.md                   # Petunjuk instalasi & penggunaan
```

---

## 🛠️ Persyaratan Sistem

- **Sistem Operasi**: Ubuntu 20.04 / 22.04 / 24.04 LTS atau Debian 10 / 11 / 12 (64-bit).
- **Spesifikasi Minimum**: 1 vCPU, 512 MB - 1 GB RAM.
- **Akses**: User **root**.

---

## 📦 Cara Deploy & Menjalankan di VPS

### Langkah 1: Clone atau Download ke VPS

Masuk ke VPS via SSH sebagai `root`, lalu unduh project ini (misal via repository GitHub Anda atau langsung salin):

```bash
git clone https://github.com/USERNAME/ssh-premium-autoscript.git
cd ssh-premium-autoscript
chmod +x install.sh
./install.sh
```

### Langkah 2: Menjalankan Installer
Saat installer berjalan, Anda akan diminta memasukkan nama domain / Bug Host (opsional). Jika tidak memiliki domain khusus, tekan **ENTER** untuk menggunakan IP publik VPS Anda.

Installer akan menyelesaikan seluruh konfigurasi secara otomatis dalam waktu 1-2 menit.

---

## 🎮 Cara Menggunakan

Setelah instalasi selesai, cukup ketik perintah berikut di terminal VPS:

```bash
menu
```

Menu interaktif akan muncul:
- **Pilihan [1]**: Buat akun SSH Premium baru (masukkan username, password, dan masa aktif hari).
- **Pilihan [2]**: Hapus akun SSH yang ada.
- **Pilihan [3]**: Cek pengguna yang sedang aktif/login.
- **Pilihan [4]**: Lihat daftar seluruh akun beserta tanggal kadaluarsanya.
- **Pilihan [5]**: Restart seluruh layanan tunnel sekaligus.

---

## 🌐 Konfigurasi Cloudflare CDN (Untuk WebSocket Port 80)

Jika ingin menggunakan tunneling SSH WebSocket melalui Cloudflare CDN:
1. Arahkan DNS **A Record** domain Anda (misal `sg1.domainanda.com`) ke IP Publik VPS dengan status **Proxied (Awan Oranye)** di Cloudflare.
2. Di aplikasi client (seperti HTTP Custom / NapsternetV / NetMod):
   - **SSH Host**: Domain Anda (`sg1.domainanda.com`) atau Bug Host operator yang ter-sni.
   - **Port**: `80` (atau `8880`)
   - **Payload**:
     ```http
     GET / HTTP/1.1[crlf]Host: sg1.domainanda.com[crlf]Upgrade: websocket[crlf][crlf]
     ```

