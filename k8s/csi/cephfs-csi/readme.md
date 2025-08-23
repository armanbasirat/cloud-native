```diff
# csiConfig:
#   - clusterID: "<ceph-cluster-id>"
#     monitors:
#       - "<mon1-ip:6789>"
#       - "<mon2-ip:6789>"
#       - "<mon3-ip:6789>"
#       - "<mon4-ip:6789>"
#       - "<mon5-ip:6789>"
#     cephFS:
#       subvolumeGroup: "k8s-<cluster-name>-svg"
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

```diff
helm upgrade --install ceph-csi-cephfs ceph-csi-cephfs-3.14.2 \
  --namespace ceph-csi-cephfs \
  --create-namespace
```