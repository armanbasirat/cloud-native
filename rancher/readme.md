<p align="center" width="100%">
    <img width="15%" src="https://ranchermanager.docs.rancher.com/img/rancher-logo-horiz-color.svg"> 
</p>

# Install [Rancher] on a Kubernetes Cluster (https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster)

#### Requirements

+ Kubernetes Cluster
+ Ingress Controller
+ CLI Tools


```
helm upgrade --install cert-manager cert-manager-v1.18.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```

```
kubectl get pods --namespace cert-manager
```

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