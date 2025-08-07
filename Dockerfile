FROM ubuntu:24.04

# 设置非交互模式，避免 tzdata 配置时的交互提示
ENV TZ=Asia/Shanghai
ENV DEBIAN_FRONTEND=noninteractive

# 更新包列表，安装 tzdata（时区数据），并设置时区
RUN apt-get update && \
    apt-get install -y tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 可选：验证时区
RUN date


# 安装依赖
RUN apt-get update && apt-get install -y \
    openvpn \
    easy-rsa \
    openvpn-auth-ldap \
    iptables \
    gettext-base \
    iproute2 \
    iputils-ping \
    tcpdump \
    traceroute \
    vim \
    && rm -rf /var/lib/apt/lists/*
    


# 创建目录结构
RUN mkdir -p /etc/openvpn/certs \
    /etc/openvpn/auth \
    /etc/openvpn/client-configs \
    /usr/local/bin

# 添加配置文件和脚本
COPY entrypoint.sh /usr/local/bin/
COPY configs/server.conf.template /etc/openvpn/
COPY configs/client.conf.template /etc/openvpn/
COPY configs/ldap.conf.template /etc/openvpn/auth/

# 证书生成脚本
COPY scripts/generate-certs.sh /usr/local/bin/
COPY scripts/generate-client-config.sh /usr/local/bin/

# 设置权限
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/generate-certs.sh \
    && chmod +x /usr/local/bin/generate-client-config.sh

# 开放VPN端口
EXPOSE 1194/udp

# 持久化存储
VOLUME ["/etc/openvpn/certs"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
