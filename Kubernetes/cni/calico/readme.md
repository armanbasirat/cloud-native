#### create ippool

```diff
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  name: ns1-ippool
spec:
  cidr: 10.233.128.0/26
  blockSize: 29
  ipipMode: Never
  natOutgoing: true
  vxlanMode: Always
  nodeSelector: "!all()"
```

### annotate namespace with specific ippool

```diff
apiVersion: v1
kind: Namespace
metadata:
  name: ns1
  annotations:
    field.cattle.io/projectId: "<cluster-id>:<project-id>"
    "cni.projectcalico.org/ipv4pools": "[\"ns1-ippool\"]"
```