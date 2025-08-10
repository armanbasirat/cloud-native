```
apt install -y keepalived
```

## copy check_nginx.sh and keepalived.conf to the node1 and node2

```
systemctl enable keepalived
systemctl start keepalived
```