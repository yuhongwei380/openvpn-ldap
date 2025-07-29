FROM ubuntu:22.04

# 安装依赖
RUN apt-get update && apt-get install -y \
    openvpn \
    easy-rsa \
    openvpn-auth-ldap \
    iptables \
    ip6tables \
    && rm -rf /var/lib/apt/lists/*

# 创建目录结构
RUN mkdir -p /etc/openvpn/certs /etc/openvpn/auth /etc/openvpn/client-templates

# 添加配置文件和脚本
COPY entrypoint.sh /usr/local/bin/
COPY server.conf.template /etc/openvpn/
COPY ldap.conf.template /etc/openvpn/auth/

# 证书生成脚本
COPY generate-certs.sh /usr/local/bin/

# 设置权限
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/generate-certs.sh

# 开放VPN端口
EXPOSE 1194/udp

# 持久化存储
VOLUME ["/etc/openvpn/certs"]

ENTRYPOINT ["entrypoint.sh"]
CMD ["openvpn", "--config", "/etc/openvpn/server.conf"]