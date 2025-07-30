Info about this project
Openvpn Connect to LDAP with this project : https://github.com/ahaenggli/AzureAD-LDAP-wrapper


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
```
