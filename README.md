# Info about this project

Openvpn Connect to LDAP with this project : AzureAD-LDAP-wrapper

Configure the AzureAD application according to the requirements of the following project

https://github.com/ahaenggli/AzureAD-LDAP-wrapper

AzureAD-LDAP-wrapper is a ldap which connect with AzureAD (Now is the Entra ID)

This OpenVPN default Seting LDAP Search :`SearchFilter    (mail=%u)`

# Using

## 1. Download file 

```
mkdir vpn
mkdir -p  vpn/certs
```
!!!! You should Prepare certificate ！ 

`ca.crt`  、  `dh.pem`  、`server.crt` 、 `server.key`

Also，you can Using the config to create the cert In ENV file
```
GENERATE_CERTS=false     #change false  to true 
```

`docker-compose.yml` and  `.env` file in the repo ,you shoud download it and change the infomation  to yourself
then, do it !
```
docker-compose up -d 
```

## 2. get the client profile
```
docker exec openvpn-ldap /usr/local/bin/generate-client-config.sh my-client
docker cp openvpn-ldap:/etc/openvpn/client-configs/my-client.ovpn ./
```

## 3. support the IPV4 & IPV6

introduce：
`10.7.0.0/16`  is your vpn network
our test env based on IPV6 NAT66 ,so the vm ' ipv6 address is not public IPV6 address ,also the docker network IPV6 is not public IPV6 address
`fd00:2024:dbf:0000:2290::/80` is your docker network for IPV6

/etc/docker/daemon.json
```
"ipv6": true,
"fixed-cidr-v6": "fd00:2024:dbf:0000:2290::/80"

```
then,
```
systemctl daemon-reload
systemctl restart docker 
```

## 4. Get the Client Config
```
docker cp openvpn-ldap:/etc/openvpn/client-configs/default-client.ovpn ./
```

## 5.Setting the NAT
NAT from vm with docker
```
sudo iptables -t nat -A POSTROUTING -s 10.7.0.0/16 -o eth0 -j MASQUERADE
sudo ip6tables -t nat -A POSTROUTING -s fd00:2024:dbf:0000:2290::/80 -o  eth0 -j MASQUERADE
```
永久保存：
```
sudo apt install iptables-persistent
sudo iptables-save > /etc/iptables/rules.v4
sudo systemctl enable --now iptables
```
删除 iptables
```
sudo ip6tables -t nat -D POSTROUTING -s fd12:3456:789a::/64 -o eth0 -j MASQUERADE
```


NAT SERVICE：
sudo vim /etc/systemd/system/openvpn-iptables.service
```
[Unit]
Description=OpenVPN IPTables Rules
After=network.target
Before=openvpn-server@server.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'iptables -t nat -A POSTROUTING -s 10.7.0.0/16 -o eth0 -j MASQUERADE; ip6tables -t nat -A POSTROUTING -s fd00:2024:dbf:0000:2290::/80 -o eth0 -j MASQUERADE'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```
sudo systemctl enable openvpn-iptables.service




