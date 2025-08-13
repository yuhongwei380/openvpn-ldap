# Info about this project

Openvpn Connect to LDAP with this project : AzureAD-LDAP-wrapper

https://github.com/ahaenggli/AzureAD-LDAP-wrapper

AzureAD-LDAP-wrapper is a ldap which connect with AzureAD (Now is the Entra ID)

#Using

## 1. docker-compose  with the .env

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
删除 iptables
```
sudo ip6tables -t nat -D POSTROUTING -s fd12:3456:789a::/64 -o eth0 -j MASQUERADE
```



