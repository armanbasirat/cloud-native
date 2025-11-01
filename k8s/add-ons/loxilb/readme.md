```diff
kubectl apply -f loxilb-nobgp.yaml
kubectl apply -f kube-loxilb.yaml
kubectl apply -f loxilb-url-crd.yaml
```

### Create/Update/Delete loxilb URL when running in external mode
### To add a loxilb instance to the kube-loxilb, we can use the following yaml file (save as loxiurl1.yaml) :


```diff
apiVersion: "loxiurl.loxilb.io/v1"
kind: LoxiURL
metadata:
  name: llb-10.10.10.1
spec:
  loxiURL: http://10.10.10.1:11111
  zone: llb
  type: default


kubectl apply -f loxiurl1.yaml
kubectl get loxiurl
```

### Create/Update/Delete IPAM Pool definitions to use with services
### To add a new IPAM CIDR pool to the kube-loxilb, we can use the following yaml file (save as loxipool1.yaml) :


```diff
apiVersion: "loxiurl.loxilb.io/v1"
kind: LoxiURL
metadata:
  name: pool5
spec:
  loxiURL: 12.12.12.0/24
  zone: llb
  type: cidrpool

kubectl apply -f loxipool1.yaml
```

```diff
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb1
  annotations:
    loxilb.io/poolSelect: pool5
spec:
  externalTrafficPolicy: Local
  loadBalancerClass: loxilb.io/loxilb
  selector:
    what: nginx-test
  ports:
    - port: 80
      targetPort: 80
  type: LoadBalancer
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-test
  labels:
    what: nginx-test
spec:
  #nodeSelector:
  #  node: wlznode02
  containers:
    - name: nginx-test
      image: nginx
      imagePullPolicy: Always
      ports:
        - containerPort: 80
```