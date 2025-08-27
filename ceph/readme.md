<p align="center" width="100%">
    <img width="15%" src="https://ceph.io/assets/bitmaps/Ceph_Logo_Stacked_RGB_120411_fa.png"> 
</p>

# Deploy a Production Ready Ceph Cluster with [Cephadm](https://docs.ceph.com/en/latest/cephadm/install/#cephadm-deploying-new-cluster)


#### Requirements

+ Python 3
+ Systemd
+ Podman or Docker for running containers
+ Time synchronization (such as Chrony or the legacy ntpd)
+ LVM2 for provisioning storage devices


## Step 01: prepare os and servers


### update all nodes

```
apt update
apt upgrade -y
```

### reboot server

```
reboot
```

### remove old packages

```
apt autoremove -y
```

### check chrony configuration

```
chronyc sources
```

### check dns configuration

```
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: false
      dhcp6: false
      addresses:
      - <cidr>
      routes:
      - to: default
        via: <gateway>
      nameservers:
       addresses:
         - <dns1>
         - <dns2>
```


### add nodes hostname in dns server or in /etc/hosts on all nodes

```
cat << 'EOF' | sudo tee -a /etc/hosts >/dev/null
<mon1-ip> <mon1-hostname>
<mon2-ip> <mon2-hostname>
<mon3-ip> <mon3-hostname>
<mon4-ip> <mon4-hostname>
<mon5-ip> <mon5-hostname>

<osd1-ip> <osd1-hostname>
<osd2-ip> <osd2-hostname>
<osd3-ip> <osd3-hostname>
EOF
```

## Step 02: install and configure docker

```
sudo apt install -y docker.io
```

```
cat << 'EOF' > /etc/docker/daemon.json
{
  "insecure-registries": ["0.0.0.0/0"],
  "live-restore": true
}
EOF
```

```
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## Step 03: pull and tag images on all nodes

```
docker pull <quay-repository>/ceph/ceph:v19
docker pull <quay-repository>/ceph/grafana:10.4.0
docker pull <quay-repository>/ceph/promtail:3.0.0
docker pull <quay-repository>/ceph/loki:3.0.0
docker pull <quay-repository>/prometheus/prometheus:v2.51.0
docker pull <quay-repository>/prometheus/node-exporter:v1.7.0
docker pull <quay-repository>/prometheus/alertmanager:v0.25.0
```


```
docker tag <quay-repository>/ceph/ceph:v19  quay.io/ceph/ceph:v19
docker tag <quay-repository>/ceph/grafana:10.4.0 quay.io/ceph/grafana:10.4.0
docker tag <quay-repository>/ceph/promtail:3.0.0 quay.io/ceph/promtail:3.0.0
docker tag <quay-repository>/ceph/loki:3.0.0 quay.io/ceph/loki:3.0.0
docker tag <quay-repository>/prometheus/prometheus:v2.51.0 quay.io/prometheus/prometheus:v2.51.0
docker tag <quay-repository>/prometheus/node-exporter:v1.7.0 quay.io/prometheus/node-exporter:v1.7.0
docker tag <quay-repository>/prometheus/alertmanager:v0.25.0 quay.io/prometheus/alertmanager:v0.25.0
```


## Step 04: bootstrap cluster

### install cephadm and requirement tools on first mon node

```
mkdir workspace
cd workspace

CEPH_RELEASE=19.2.3
# curl --remote-name --location http://<nexus-ceph-repository>/rpm-${CEPH_RELEASE}/el9/noarch/cephadm
curl --remote-name --location http://192.168.106.12:8081/repository/download.ceph.com/rpm-${CEPH_RELEASE}/el9/noarch/cephadm

chmod +x cephadm
cp cephadm /usr/local/bin

apt install -y ceph-common
```

### bootstrap new cluster

```
cephadm bootstrap --mon-ip <mon1-ip> \
--allow-fqdn-hostname \
--initial-dashboard-user admin \
--initial-dashboard-password P@ssw0rd \
--dashboard-password-noupdate \
--skip-firewalld \
--with-centralized-logging \
--skip-pull
```

### check cluster status

```
cephadm shell -- ceph -s
ceph status
```

## Step 05: configure grafana and set admin password

```
cat << 'EOF' > grafana.yml
service_type: grafana
spec:
  initial_admin_password: P@ssw0rd
EOF
```

```
ceph orch apply -i grafana.yml
ceph orch redeploy grafana
```

## Step 06: copy ssh-key on all other ceph nodes 

```
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<mon2-ip>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<mon3-ip>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<mon4-ip>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<mon5-ip>

ssh-copy-id -f -i /etc/ceph/ceph.pub root@<osd1-ip>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<osd2-ip>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<osd3-ip>
```

## step 06: Add other nodes

```
ceph orch host add <mon1-hostname> <mon1-ip> --labels _admin,mon,mgr,mds
ceph orch host add <mon2-hostname> <mon2-ip> --labels _admin,mon,mgr,mds
ceph orch host add <mon3-hostname> <mon3-ip> --labels _admin,mon,mgr,mds
ceph orch host add <mon4-hostname> <mon4-ip> --labels _admin,mon,mgr,mds
ceph orch host add <mon5-hostname> <mon5-ip> --labels _admin,mon,mgr,mds

ceph orch host add <osd1-hostname> <osd1-ip> --labels osd
ceph orch host add <osd2-hostname> <osd2-ip> --labels osd
ceph orch host add <osd3-hostname> <osd3-ip> --labels osd
```

## step 07: create osds

```
ceph orch daemon add osd <osd1-hostname>:/dev/sdX
ceph orch daemon add osd <osd2-hostname>:/dev/sdX
ceph orch daemon add osd <osd3-hostname>:/dev/sdX

ceph osd tree
ceph osd ls
```

## step 08: create mds servcie

```
cat << 'EOF' > mds.yml
service_type: mds
service_id: <service-id>
placement:
  count: 3
  label: mds
EOF

ceph orch apply -i mds.yaml
ceph orch ls | grep -i mds
```

## step 09: create pool and filesystem


```
ceph osd pool create k8s-<cluster-name>-cephfs-data
ceph osd pool create k8s-<cluster-name>-cephfs-metadata
ceph osd pool ls

ceph fs new k8s-<cluster-name>-fs k8s-<cluster-name>-cephfs-metadata k8s-<cluster-name>-cephfs-data
ceph fs ls

ceph fs subvolumegroup create k8s-<cluster-name>-fs k8s-<cluster-name>-svg
ceph fs subvolumegroup ls k8s-<cluster-name>-fs
```


## step 10: create user for k8s


```
user_name=k8s-<cluster-name>-cephfs
fs_name=k8s-<cluster-name>-fs
metadata_name=k8s-<cluster-name>-cephfs-metadata
data_name=k8s-<cluster-name>-cephfs-data
svg_name=k8s-<cluster-name>-svg
```

```
ceph auth get-or-create client.$user_name \
  mgr "allow rw" \
  osd "allow rwx tag cephfs metadata=$metadata_name, allow rw tag cephfs data=$data_name" \
  mds "allow r fsname=$fs_name path=/volumes, allow rws fsname=$fs_name path=/volumes/$svg_name" \
  mon "allow r fsname=$fs_name"
```

## step 11: create and apply os tuning profile

```
cat << 'EOF' > mon-tune-profile.yml
profile_name: mon-tune-profile
placement:
  hosts:
    - <mon1>
    - <mon2>
    - <mon3>
    - <mon4>
    - <mon5>
    - <osd1>
    - <osd2>
    - <osd3>
settings:
  fs.file-max: 1000000
  vm.swappiness: '13'
EOF

ceph orch tuned-profile apply -i mon-tune-profile.yml
```


## step 12: access to ceph dashboard

```
https://<mon1-ip>:8443
```

## step 12: access to monitoring and observability

```
# grafana
https://<mon1-ip>:3000

# prometheus
http://<mon1-ip>:9095

# alertmanager
http://<mon1-ip>:9093
```