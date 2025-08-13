#!/bin/bash

set -e

CERT_DIR="/etc/openvpn/certs"
CA_DIR="/etc/openvpn/ca"

echo "🔐 开始生成OpenVPN证书..."

# 创建必要的目录
mkdir -p "$CERT_DIR"
mkdir -p "$CA_DIR"

# 检查 easyrsa 命令
if ! command -v easyrsa &> /dev/null; then
    echo "❌ easyrsa 命令未找到"
    # 查找 easyrsa 位置
    EASYRSA_PATH=$(find /usr -name "easyrsa" 2>/dev/null | head -1)
    if [ -n "$EASYRSA_PATH" ]; then
        echo "✅ 找到 easyrsa: $EASYRSA_PATH"
        EASYRSA_CMD="$EASYRSA_PATH"
    else
        echo "❌ 无法找到 easyrsa 命令"
        exit 1
    fi
else
    EASYRSA_CMD="easyrsa"
    echo "✅ 使用 easyrsa 命令: $(which easyrsa)"
fi

# 初始化 CA 目录
cd "$CA_DIR"

# 创建 vars 文件（新版本语法）
cat > vars << 'EOF'
export EASYRSA_REQ_COUNTRY="CN"
export EASYRSA_REQ_PROVINCE="Beijing"
export EASYRSA_REQ_CITY="Beijing"
export EASYRSA_REQ_ORG="OpenVPN"
export EASYRSA_REQ_EMAIL="admin@example.com"
export EASYRSA_REQ_OU="OpenVPN"
export EASYRSA_KEY_SIZE=2048
export EASYRSA_CA_EXPIRE=3650
export EASYRSA_CERT_EXPIRE=3650
EOF

# 初始化 PKI
echo "🔧 初始化 PKI..."
"$EASYRSA_CMD" init-pki

# 生成 CA（交互式，使用 echo 模拟输入）
echo "🔏 生成 CA 证书..."
echo -e "\n" | "$EASYRSA_CMD" build-ca nopass

# 生成服务器证书
echo "🖥️ 生成服务器证书..."
echo "server" | "$EASYRSA_CMD" build-server-full server nopass

# 生成 DH 参数
echo "🔢 生成 DH 参数..."
"$EASYRSA_CMD" gen-dh

# 生成 TLS 密钥
echo "🔑 生成 TLS 密钥..."
openvpn --genkey secret "$CERT_DIR/ta.key"

# 复制证书文件到正确位置
echo "📋 复制证书文件..."

# 新版本的路径结构
if [ -f "pki/ca.crt" ] && [ -f "pki/issued/server.crt" ] && [ -f "pki/private/server.key" ] && [ -f "pki/dh.pem" ]; then
    cp "pki/ca.crt" "$CERT_DIR/"
    cp "pki/issued/server.crt" "$CERT_DIR/"
    cp "pki/private/server.key" "$CERT_DIR/"
    cp "pki/dh.pem" "$CERT_DIR/"
    echo "✅ 证书文件复制成功"
else
    echo "❌ 证书文件未找到，检查路径:"
    find pki -name "*.crt" -o -name "*.key" -o -name "*.pem" 2>/dev/null || echo "pki 目录内容:"
    ls -la pki/ 2>/dev/null || echo "无 pki 目录"
    exit 1
fi

# 验证文件
echo "✅ 验证生成的证书..."
REQUIRED_FILES=("ca.crt" "server.crt" "server.key" "dh.pem" "ta.key")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$CERT_DIR/$file" ]; then
        echo "❌ 缺少证书文件: $CERT_DIR/$file"
        ls -la "$CERT_DIR/" 2>/dev/null || echo "证书目录内容:"
        exit 1
    else
        echo "✅ $file 存在"
    fi
done

# 设置权限
echo "🛡️ 设置文件权限..."
chmod 600 "$CERT_DIR/server.key" "$CERT_DIR/ta.key" 2>/dev/null || true
chmod 644 "$CERT_DIR/ca.crt" "$CERT_DIR/server.crt" "$CERT_DIR/dh.pem" 2>/dev/null || true

echo "🎉 证书生成完成！"
ls -la "$CERT_DIR/"
