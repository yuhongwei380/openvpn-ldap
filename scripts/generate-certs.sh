#!/bin/bash

CERT_DIR="/etc/openvpn/certs"
EASYRSA_DIR="$HOME/openvpn-ca"
EASYRSA_PKI="$EASYRSA_DIR/pki"

# 创建 CA 目录结构
mkdir /etc/openvpn/certs/
make-cadir "$EASYRSA_DIR"
cd "$EASYRSA_DIR"

# 配置 vars 文件（可选：如果需要默认值可以预先写入）
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

# 构建 CA（交互式输入，或使用 --batch 和预设信息）
./easyrsa --pki-dir="$EASYRSA_PKI" build-ca nopass

# 生成服务器证书
./easyrsa --pki-dir="$EASYRSA_PKI" build-server-full server nopass

# 生成 Diffie-Hellman 参数
./easyrsa --pki-dir="$EASYRSA_PKI" gen-dh

# 生成 HMAC 签名密钥 (TLS auth key)
openvpn --genkey secret "$CERT_DIR/ta.key"

# 可选：生成客户端证书
# ./easyrsa --pki-dir="$EASYRSA_PKI" build-client-full client1 nopass

# 设置权限
chmod 600 "$EASYRSA_PKI/private/"*.key "$CERT_DIR/ta.key"
chmod 644 "$EASYRSA_PKI/issued/"*.crt "$EASYRSA_PKI/ca.crt" "$EASYRSA_PKI/dh.pem"

# 如果 ta.key 放在 /etc/openvpn/certs 下，请确保路径一致
chmod 600 "$CERT_DIR/ta.key"

# 拷贝证书到 OpenVPN 服务器目录
cd "$EASYRSA_DIR"
sudo cp "$EASYRSA_PKI/ca.crt" "$EASYRSA_PKI/issued/server.crt" "$EASYRSA_PKI/private/server.key" "$EASYRSA_PKI/dh.pem" /etc/openvpn/certs/
