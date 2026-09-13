<p align="center" width="100%">
    <img width="30%" src="https://ranchermanager.docs.rancher.com/img/rancher-logo-horiz-color.svg"> 
</p>

# Deploy [Rancher](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster) on a Kubernetes Cluster

#### Requirements

+ Kubernetes Cluster
+ Ingress Controller
+ CLI Tools (kubectl, helm)


## step 01: deploy cert-manager

```
helm upgrade --install cert-manager cert-manager-v1.18.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```

```
kubectl get pods --namespace cert-manager
```

## step 02: deploy rancher

```
helm upgrade --install rancher rancher-2.11.3 \
  --namespace cattle-system \
  --create-namespace \
  --set hostname=rancher.example.org \
  --set bootstrapPassword=admin
```

```
kubectl -n cattle-system rollout status deploy/rancher
kubectl -n cattle-system get deploy rancher
```


## step 03: configure external auth 

```
ldapsearch -x -D "acme\jdoe" -H ldap://ad.acme.com:389 -b "dc=acme,dc=com" -s sub "sAMAccountName=jdoe"
```



## step 04: Expand Rancher certificate to 'five' years

```
k -n cattle-system edit certificate tls-rancher-ingress
```

#### Append these two values in 'spec'

```
duration: 43800h
renewBefore: 720h
```

#### Example

```
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tls-rancher-ingress
  namespace: cattle-system
spec:
  dnsNames:
  - rancher.test.local
  duration: 43800h
  renewBefore: 720h
  issuerRef:
    group: cert-manager.io
    kind: Issuer
    name: rancher
  secretName: tls-rancher-ingress
  usages:
  - digital signature
  - key encipherment
```

#### Delete existing certificate (Cert manager will create new certificate)

```
k -n cattle-system delete secret tls-rancher-ingress
```