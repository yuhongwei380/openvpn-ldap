Info about this project
Openvpn Connect to LDAP with this project : AzureAD-LDAP-wrapper
https://github.com/ahaenggli/AzureAD-LDAP-wrapper

AzureAD-LDAP-wrapper is a ldap which connect with AzureAD (Now is the Entra ID)

Using

1. docker-compose  with the .env

2. get the client profile
```
docker exec openvpn-ldap /usr/local/bin/generate-client-config.sh my-client
docker cp openvpn-ldap:/etc/openvpn/client-configs/my-client.ovpn ./
```

3. support the IPV4 & IPV6

NAT from vm with docker
`10.8.0.0/24`  is your vpn network
```
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
sudo ip6tables -t nat -A POSTROUTING -s fd00:2024:dbf:0000:2290::/80 -o  eth0 -j MASQUERADE
```
删除 iptables
```
sudo ip6tables -t nat -D POSTROUTING -s fd12:3456:789a::/64 -o eth0 -j MASQUERADE
```


daemon.json
```
"ipv6": true,
"fixed-cidr-v6": "fd00:2024:dbf:0000:2290::/80"

```
