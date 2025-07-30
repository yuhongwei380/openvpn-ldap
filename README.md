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
