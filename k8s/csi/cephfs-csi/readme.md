# Deploy cephfs-csi

## Step 01: edit values.yaml


```diff
csiConfig:
  [{
     "cephFS": {
       "subvolumeGroup": "k8s-<cluster-name>-svg"
     },
     "clusterID": "<ceph-cluster-id>",
     "monitors": [
        "<mon1-ip>:6789",
        "<mon1-ip>:6789",
        "<mon1-ip>:6789",
        "<mon1-ip>:6789"
     ]
  }]
```

```diff
# clustername: "<k8s-cluster-name>"
```

```diff
#  snapshotter:
#    args:
#      enableVolumeGroupSnapshots: true
```

```diff
# storageClass:
#   create: true
#   annotations:
#      storageclass.kubernetes.io/is-default-class: "true"
#   clusterID: <ceph-cluster-id>
#   fsName: k8s-<cluster-name>-fs
#   pool: "k8s-<cluster-name>-cephfs-data"
#   provisionerSecretNamespace: "ceph-csi-cephfs"
#   controllerExpandSecretNamespace: "ceph-csi-cephfs"
#   nodeStageSecretNamespace: "ceph-csi-cephfs"
```

```diff
# secret:
#   create: true
#   userID: k8s-<cluster-name>-cephfs
#   userKey: <Ceph auth key corresponding to the userID above>
```

## Step 02: deploy with helm

```diff
helm upgrade --install ceph-csi-cephfs ceph-csi-cephfs-3.14.2 \
  --namespace ceph-csi-cephfs \
  --create-namespace

helm ls -n ceph-csi-cephfs
```

```diff
kubectl -n ceph-csi-cephfs get pods
```

## Step 02: deploy test nginx app with cephfs pvc

```diff
cat << 'EOF' > cephfs-deployment.yml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cephfs-deployment-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-cephfs-sc
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: cephfs-deployment
  name: cephfs-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cephfs-deployment
  template:
    metadata:
      labels:
        app: cephfs-deployment
    spec:
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: cephfs-deployment-pvc
      containers:
      - image: nginx
        name: nginx
        volumeMounts:
        - name: data
          mountPath: /var/lib/www/html
---
apiVersion: v1
kind: Service
metadata:
  name: cephfs-deployment-svc
spec:
  type: ClusterIP
  selector:
    app: cephfs-deployment
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
EOF
```

```diff
kubectl apply -f cephfs-deployment.yml

kubectl get pods
kubectl get pvc
```



```diff
cat << 'EOF' > cephfs-dd.yml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cephfs-dd-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: csi-cephfs-sc
  resources:
    requests:
      storage: 1Gi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cephfs-dd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cephfs-dd
  template:
    metadata:
      labels:
        app: cephfs-dd
    spec:
      containers:
      - name: cephfs-dd
        image: busybox
        command: ["/bin/sh", "-c"]
        args:
          - |
            echo "=== Testing CephFS Mount ==="
            df -h /mnt/cephfs || true
            echo "=== Write Test ==="
            dd if=/dev/zero of=/mnt/cephfs/testfile bs=1M count=100 oflag=direct
            echo "=== Read Test ==="
            dd if=/mnt/cephfs/testfile of=/dev/null bs=1M iflag=direct
            echo "=== Listing Files ==="
            ls -lh /mnt/cephfs
            echo "=== Test Complete ==="
            sleep 3600
        volumeMounts:
        - name: cephfs-dd-vol
          mountPath: /mnt/cephfs
      volumes:
      - name: cephfs-dd-vol
        persistentVolumeClaim:
          claimName: cephfs-dd-pvc
EOF
```

```diff
kubectl apply -f cephfs-dd.yml

kubectl get pods
kubectl get pvc
```


```diff
cat << 'EOF' > cephfs-fio.yml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cephfs-fio-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: csi-cephfs-sc
  resources:
    requests:
      storage: 1Gi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cephfs-fio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cephfs-fio
  template:
    metadata:
      labels:
        app: cephfs-fio
    spec:
      containers:
      - name: cephfs-fio
        image: ljishen/fio
        command: ["fio"]
        args:
          - "--name=cephfs-dd"
          - "--directory=/mnt/cephfs"
          - "--rw=randrw"
          - "--bs=4k"
          - "--size=512M"
          - "--numjobs=4"
          - "--runtime=60"
          - "--time_based"
          - "--group_reporting"
        volumeMounts:
        - name: cephfs-fio-vol
          mountPath: /mnt/cephfs
      volumes:
      - name: cephfs-fio-vol
        persistentVolumeClaim:
          claimName: cephfs-fio-pvc
EOF
```


```diff
kubectl apply -f cephfs-fio.yml

kubectl get pods
kubectl get pvc
```