#!/bin/bash

CERT_DIR="/etc/openvpn/certs"
EASYRSA_DIR="/root/openvpn-ca"
EASYRSA_PKI="$EASYRSA_DIR/pki"

# 创建必要的目录
mkdir -p "$CERT_DIR"
mkdir -p "$EASYRSA_DIR"

# 创建 CA 目录结构
make-cadir "$EASYRSA_DIR"
cd "$EASYRSA_DIR"

# 配置 vars 文件
cat > vars <<EOF
export KEY_COUNTRY="CN"
export KEY_PROVINCE="ZJ"
export KEY_CITY="HZ"
export KEY_ORG="yueshu"
export KEY_EMAIL="it-admin@vesoft.com"
export KEY_OU="IT"
export KEY_NAME="server"
EOF

# 初始化 PKI
./easyrsa --pki-dir="$EASYRSA_PKI" init-pki

# 构建 CA（使用 batch 模式避免交互）
./easyrsa --pki-dir="$EASYRSA_PKI" --batch build-ca nopass

# 生成服务器证书
./easyrsa --pki-dir="$EASYRSA_PKI" --batch build-server-full server nopass

# 生成 Diffie-Hellman 参数（如果不存在）
if [ ! -f "$EASYRSA_PKI/dh.pem" ]; then
    ./easyrsa --pki-dir="$EASYRSA_PKI" gen-dh
fi

# 生成 HMAC 签名密钥 (TLS auth key)
openvpn --genkey secret "$CERT_DIR/ta.key"

# 设置权限（先检查文件是否存在）
if [ -d "$EASYRSA_PKI/private/" ]; then
    chmod 600 "$EASYRSA_PKI/private/"*.key 2>/dev/null || echo "No key files to chmod"
fi

if [ -d "$EASYRSA_PKI/issued/" ]; then
    chmod 644 "$EASYRSA_PKI/issued/"*.crt 2>/dev/null || echo "No certificate files to chmod"
fi

if [ -f "$EASYRSA_PKI/ca.crt" ]; then
    chmod 644 "$EASYRSA_PKI/ca.crt"
fi

if [ -f "$EASYRSA_PKI/dh.pem" ]; then
    chmod 644 "$EASYRSA_PKI/dh.pem"
fi

chmod 600 "$CERT_DIR/ta.key"

# 拷贝证书到 /etc/openvpn/certs 目录
echo "Copying certificates to $CERT_DIR directory..."

# 检查源文件是否存在
if [ -f "$EASYRSA_PKI/ca.crt" ] && \
   [ -f "$EASYRSA_PKI/issued/server.crt" ] && \
   [ -f "$EASYRSA_PKI/private/server.key" ] && \
   [ -f "$EASYRSA_PKI/dh.pem" ]; then
    
    cp "$EASYRSA_PKI/ca.crt" "$CERT_DIR/"
    cp "$EASYRSA_PKI/issued/server.crt" "$CERT_DIR/"
    cp "$EASYRSA_PKI/private/server.key" "$CERT_DIR/"
    cp "$EASYRSA_PKI/dh.pem" "$CERT_DIR/"
    
    # 同时拷贝 ta.key
    cp "$CERT_DIR/ta.key" "$CERT_DIR/"
    
    echo "Certificates copied successfully to $CERT_DIR!"
else
    echo "Error: Some certificate files are missing:"
    [ ! -f "$EASYRSA_PKI/ca.crt" ] && echo "  - ca.crt"
    [ ! -f "$EASYRSA_PKI/issued/server.crt" ] && echo "  - server.crt"
    [ ! -f "$EASYRSA_PKI/private/server.key" ] && echo "  - server.key"
    [ ! -f "$EASYRSA_PKI/dh.pem" ] && echo "  - dh.pem"
fi

# 设置最终权限
chmod 600 "$CERT_DIR/"*.key 2>/dev/null || echo "No key files to chmod in final directory"
chmod 644 "$CERT_DIR/"*.crt "$CERT_DIR/"*.pem 2>/dev/null || echo "No cert/pem files to chmod in final directory"

# 列出生成的文件
echo "Generated files in $CERT_DIR:"
ls -la "$CERT_DIR/" 2>/dev/null || echo "Certificate directory not found"
