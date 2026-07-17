# Deploy Metallb

```diff
helm upgrade --install metallb metallb-0.15.2 \
  --namespace metallb-system \
  --create-namespace

helm ls -n metallb
kubectl get pods -n metallb-system
```

## create pool

```
cat << 'EOF' > pool-1.yml

apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool-1
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.1-192.168.1.10
  - 42.176.25.64/30
  autoAssign: false
EOF

```

## create l2advertisement

```
cat << 'EOF' > l2advertisement.yml

apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advertisement-pool-1
  namespace: metallb-system
spec:
  ipAddressPools:
  - pool-1
EOF

```

## create service

```
apiVersion: v1
kind: Service
metadata:
  name: nginx
  annotations:
    metallb.io/address-pool: pool-1
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
  type: LoadBalancer
  externalTrafficPolicy: Local
```

## create service

```
apiVersion: v1
kind: Service
metadata:
  name: nginx
  annotations:
    metallb.io/loadBalancerIPs: 192.168.1.1
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
  type: LoadBalancer
```

## create service

```
apiVersion: v1
kind: Service
metadata:
  name: dns-service-tcp
  namespace: default
  annotations:
    metallb.io/allow-shared-ip: "key-to-share-1.2.3.4"
spec:
  type: LoadBalancer
  loadBalancerIP: 1.2.3.4
  ports:
    - name: dnstcp
      protocol: TCP
      port: 53
      targetPort: 53
  selector:
    app: dns
---
apiVersion: v1
kind: Service
metadata:
  name: dns-service-udp
  namespace: default
  annotations:
    metallb.io/allow-shared-ip: "key-to-share-1.2.3.4"
spec:
  type: LoadBalancer
  loadBalancerIP: 1.2.3.4
  ports:
    - name: dnsudp
      protocol: UDP
      port: 53
      targetPort: 53
  selector:
    app: dns
```

