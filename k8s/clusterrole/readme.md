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
- kind: Group
  name: system:authenticated
- kind: Group
  name: "activedirectory_group://CN=group-1,OU=groups,DC=test,DC=local"
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
kind: ClusterRole
metadata:
  name: keda-cr
rules:
- apiGroups: ["keda.sh"]
  resources: ["*"]
  verbs: ["*"]
```

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: keda-crb
subjects:
- kind: User
  name: <user-id>
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: keda-cr
  apiGroup: rbac.authorization.k8s.io
```

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    k8s-app: filebeat
  name: mw-filebeat
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: mw-filebeat
subjects:
- kind: ServiceAccount
  name: mw-sa
  namespace: <ns-name>
```

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    k8s-app: filebeat
  name: mw-filebeat
rules:
- apiGroups: [""]
  resources:
  - namespaces
  - pods
  - nodes
  - nodes/stats
  - nodes/metrics
  - pods/metrics
  - pods/stats
  - events
  - services
  - configmaps
  verbs:
  - get
  - watch
  - list
- apiGroups: ["extensions"]
  resources:
  - replicasets
  verbs:
  - get
  - watch
  - list
- apiGroups: ["coordination.k8s.io"]
  resources:
  - leases
  verbs:
  - get
  - create
  - update
- apiGroups: ["apps"]
  resources:
  - statefulsets
  - deployments
  - replicasets
  - daemonsets
  verbs:
  - get
  - watch
  - list
- apiGroups: ["rbac.authorization.k8s.io"]
  resources:
  - clusterrolebindings
  - clusterroles
  - rolebidnings
  - roles
  verbs:
  - get
  - watch
  - list
- nonResourceURLs: ["/metrics", "/stats", "/stats/summary"]
  verbs: ["get"]

```
