## deploy rook-ceph with helm ##

create ns rook-ceph

helm upgrade --install rook-ceph rook-ceph -f ../custom-values/rook-operator-values.yml -n rook-ceph
helm upgrade --install ceph-csi-drivers ceph-csi-drivers -f ../custom-values/ceph-csi-drivers-values.yaml -n rook-ceph
helm upgrade --install rook-ceph-cluster rook-ceph-cluster -f ../custom-values/rook-ceph-cluster-values.yml -n rook-ceph

## export admin password ##
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo


## load test ##
https://oneuptime.com/blog/post/2026-03-31-rook-how-to-load-test-ceph-with-rados-bench/view
