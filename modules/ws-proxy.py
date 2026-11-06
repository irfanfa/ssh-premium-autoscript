#!/usr/bin/env python3
"""
Python WebSocket to SSH Proxy
Meneruskan HTTP Upgrade WebSocket & Direct SSH traffic ke Dropbear/OpenSSH port.
Mendukung tunneling via Cloudflare CDN (Port 80/8880/2082).
"""

import socket
import select
import threading
import sys

# Konfigurasi Default
LISTEN_HOST = '0.0.0.0'
LISTEN_PORT = 80
TARGET_HOST = '127.0.0.1'
TARGET_PORT = 109  # Dropbear port 109
BUFFER_SIZE = 8192

RESPONSE_200 = (
    b"HTTP/1.1 200 OK\r\n"
    b"Server: nginx\r\n"
    b"Content-Type: text/html; charset=UTF-8\r\n"
    b"Connection: keep-alive\r\n"
    b"Content-Length: 68\r\n\r\n"
    b"<html><body><h1>SSH WebSocket Service is Running</h1></body></html>\r\n"
)

RESPONSE_101 = (
    b"HTTP/1.1 101 Switching Protocols\r\n"
    b"Upgrade: websocket\r\n"
    b"Connection: Upgrade\r\n\r\n"
)

def pipe_sockets(client, target):
    sockets = [client, target]
    try:
        while True:
            readable, _, errors = select.select(sockets, [], sockets, 60)
            if errors:
                break
            if not readable:
                break
            for s in readable:
                other = target if s is client else client
                data = s.recv(BUFFER_SIZE)
                if not data:
                    return
                other.sendall(data)
    except Exception:
        pass
    finally:
        try:
            client.close()
        except Exception:
            pass
        try:
            target.close()
        except Exception:
            pass

def handle_client(client_socket):
    target_socket = None
    try:
        client_socket.settimeout(15.0)
        request_data = client_socket.recv(BUFFER_SIZE)
        if not request_data:
            client_socket.close()
            return

        request_lower = request_data.lower()

        # Kasus 1: WebSocket Upgrade Request
        if b"upgrade: websocket" in request_lower or b"upgrade:websocket" in request_lower:
            target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_socket.connect((TARGET_HOST, TARGET_PORT))
            client_socket.sendall(RESPONSE_101)
            client_socket.settimeout(None)
            target_socket.settimeout(None)
            pipe_sockets(client_socket, target_socket)

        # Kasus 2: Direct SSH connection passthrough
        elif request_data.startswith(b"SSH-"):
            target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_socket.connect((TARGET_HOST, TARGET_PORT))
            target_socket.sendall(request_data)
            client_socket.settimeout(None)
            target_socket.settimeout(None)
            pipe_sockets(client_socket, target_socket)

        # Kasus 3: HTTP Request biasa (Web browser / Health check / Cloudflare ping)
        else:
            client_socket.sendall(RESPONSE_200)
            client_socket.close()

    except Exception:
        try:
            client_socket.close()
        except Exception:
            pass
        if target_socket:
            try:
                target_socket.close()
            except Exception:
                pass

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else LISTEN_PORT
    target_port = int(sys.argv[2]) if len(sys.argv) > 2 else TARGET_PORT

    global TARGET_PORT
    TARGET_PORT = target_port

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind((LISTEN_HOST, port))
        server.listen(200)
    except Exception as e:
        print(f"[!] Gagal bind pada port {port}: {e}")
        sys.exit(1)

    print(f"[*] WebSocket Proxy listening on {LISTEN_HOST}:{port} -> forward to {TARGET_HOST}:{TARGET_PORT}")

    while True:
        try:
            client, addr = server.accept()
            threading.Thread(target=handle_client, args=(client,), daemon=True).start()
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"[!] Accept error: {e}")

if __name__ == '__main__':
    main()
