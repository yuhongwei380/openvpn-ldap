#!/bin/bash

set -e

CERT_DIR="/etc/openvpn/certs"
EASYRSA_DIR="/etc/openvpn/easyrsa"

echo "🔐 开始生成OpenVPN证书..."

# 创建必要的目录
mkdir -p "$CERT_DIR"
mkdir -p "$EASYRSA_DIR"

# 初始化 EasyRSA
echo "🔧 初始化 EasyRSA..."
cd "$EASYRSA_DIR"
if [ ! -f "vars" ]; then
    # 复制示例配置文件
    cp -r /usr/share/easy-rsa/* "$EASYRSA_DIR/" 2>/dev/null || true
    # 如果上面的路径不存在，创建基本结构
    if [ ! -d "pki" ]; then
        mkdir -p pki
    fi
fi

# 初始化 PKI（如果还没有初始化）
if [ ! -d "pki" ] || [ -z "$(ls -A pki)" ]; then
    echo "📁 初始化 PKI..."
    easyrsa init-pki
fi

# 生成 CA（如果不存在）
if [ ! -f "pki/ca.crt" ]; then
    echo "🔏 生成 CA 证书..."
    echo 'set_var EASYRSA_REQ_COUNTRY    "CN"' > vars
    echo 'set_var EASYRSA_REQ_PROVINCE   "Beijing"' >> vars
    echo 'set_var EASYRSA_REQ_CITY       "Beijing"' >> vars
    echo 'set_var EASYRSA_REQ_ORG        "OpenVPN"' >> vars
    echo 'set_var EASYRSA_REQ_EMAIL      "admin@example.com"' >> vars
    echo 'set_var EASYRSA_REQ_OU         "OpenVPN"' >> vars
    echo 'set_var EASYRSA_KEY_SIZE       2048' >> vars
    echo 'set_var EASYRSA_CA_EXPIRE      3650' >> vars
    echo 'set_var EASYRSA_CERT_EXPIRE    3650' >> vars
    
    # 生成 CA
    echo "yes" | easyrsa build-ca nopass
fi

# 生成服务器证书（如果不存在）
if [ ! -f "pki/issued/server.crt" ]; then
    echo "🖥️ 生成服务器证书..."
    echo "server" | easyrsa gen-req server nopass
    echo "yes" | easyrsa sign-req server server
fi

# 生成 DH 参数（如果不存在）
if [ ! -f "$CERT_DIR/dh.pem" ]; then
    echo "🔢 生成 DH 参数..."
    openssl dhparam -out "$CERT_DIR/dh.pem" 2048
fi

# 生成 TLS 密钥（如果不存在）
if [ ! -f "$CERT_DIR/ta.key" ]; then
    echo "🔑 生成 TLS 密钥..."
    openvpn --genkey secret "$CERT_DIR/ta.key"
fi

# 复制证书文件到正确位置
echo "📋 复制证书文件..."
cp -f "pki/ca.crt" "$CERT_DIR/" 2>/dev/null || true
cp -f "pki/issued/server.crt" "$CERT_DIR/" 2>/dev/null || true
cp -f "pki/private/server.key" "$CERT_DIR/" 2>/dev/null || true

# 验证证书文件是否存在
echo "✅ 验证生成的证书..."
REQUIRED_FILES=("ca.crt" "server.crt" "server.key" "dh.pem" "ta.key")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$CERT_DIR/$file" ]; then
        echo "❌ 缺少证书文件: $CERT_DIR/$file"
        ls -la "$CERT_DIR/" 2>/dev/null || echo "证书目录不存在"
        exit 1
    else
        echo "✅ $file 存在"
    fi
done

# 设置权限
echo "🛡️ 设置文件权限..."
chmod 600 "$CERT_DIR/"*.key 2>/dev/null || true
chmod 644 "$CERT_DIR/"*.crt 2>/dev/null || true
chmod 600 "$CERT_DIR/ta.key" 2>/dev/null || true
chmod 644 "$CERT_DIR/dh.pem" 2>/dev/null || true

echo "🎉 证书生成完成！"
ls -la "$CERT_DIR/"
