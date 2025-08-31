<p align="center" width="100%">
    <img width="30%" src="https://ranchermanager.docs.rancher.com/img/rancher-logo-horiz-color.svg"> 
</p>

# Install [Rancher](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster) on a Kubernetes Cluster

#### Requirements

+ Kubernetes Cluster
+ Ingress Controller
+ CLI Tools (kubectl, helm)


## step 12: deploy cert-manager

```
helm upgrade --install cert-manager cert-manager-v1.18.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```

```
kubectl get pods --namespace cert-manager
```

## step 12: deploy rancher

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


## configure external auth 

```
ldapsearch -x -D "acme\jdoe" -H ldap://ad.acme.com:389 -b "dc=acme,dc=com" -s sub "sAMAccountName=jdoe"
```