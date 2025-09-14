### namespace ClusterRole

```diff
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ns-cr
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "list", "watch"]
```

### namespace ClusterRoleBinding

```diff
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ns-crb
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ns-cr
subjects:
- kind: User
  name: <user-id>
  apiGroup: rbac.authorization.k8s.io
```

### calico ippool ClusterRole

```diff
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: calico-ippool-cr
rules:
- apiGroups: ["crd.projectcalico.org"]
  resources: ["ippools"]
  verbs: ["get", "list", "watch", "create", "update", "delete"]
```

### calico ippool ClusterRoleBinding

```diff
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: calico-ippool-crb
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: calico-ippool-cr
subjects:
- kind: User
  name: <user-id>
  apiGroup: rbac.authorization.k8s.io
```

### cluster metrics ClusterRole

```diff
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-metrics-cr
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/metrics", "nodes/stats"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
```

### cluster metrics ClusterRoleBinding

```diff
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-metrics-crb
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-metrics-cr
subjects:
- kind: User
  name: <user-id>
  apiGroup: rbac.authorization.k8s.io
```

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: <ns-name>-keda
  namespace: <ns-name>
rules:
- apiGroups: ["keda.sh"]
  resources: ["*"]
  verbs: ["*"]
```

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: <ns-name>-keda
  namespace: <ns-name>
subjects:
- kind: User
  name: u-qfxsd
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: core-online-keda
  apiGroup: rbac.authorization.k8s.io
```

