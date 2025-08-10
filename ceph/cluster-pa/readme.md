## 1- update all k8s nodes

apt update
apt upgrade -y

## 2- reboot server

## 3- purge old files

apt autoremove -y

## 4- check chrony configuration

## 5- check dns configuration in netplan


## 6- add nodes hostname in dns server or in /etc/hosts on all nodes


## 7- install and configure docker

sudo apt install -y docker.io

cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries": ["0.0.0.0/0"],
  "live-restore": true
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker


## 8- pull images on all nodes

docker pull <quay-proxy-repository>/ceph/ceph:v19
docker pull <quay-proxy-repository>/ceph/grafana:10.4.0
docker pull <quay-proxy-repository>/ceph/promtail:3.0.0
docker pull <quay-proxy-repository>/ceph/loki:3.0.0
docker pull <quay-proxy-repository>/prometheus/prometheus:v2.51.0
docker pull <quay-proxy-repository>/prometheus/node-exporter:v1.7.0
docker pull <quay-proxy-repository>/prometheus/alertmanager:v0.25.0


## 9- tag images on all nodes

docker tag <quay-proxy-repository>/ceph/ceph:v19  quay.io/ceph/ceph:v19
docker tag <quay-proxy-repository>/ceph/grafana:10.4.0 quay.io/ceph/grafana:10.4.0
docker tag <quay-proxy-repository>/ceph/promtail:3.0.0 quay.io/ceph/promtail:3.0.0
docker tag <quay-proxy-repository>/ceph/loki:3.0.0 quay.io/ceph/loki:3.0.0
docker tag <quay-proxy-repository>/prometheus/prometheus:v2.51.0 quay.io/prometheus/prometheus:v2.51.0
docker tag <quay-proxy-repository>/prometheus/node-exporter:v1.7.0 quay.io/prometheus/node-exporter:v1.7.0
docker tag <quay-proxy-repository>/prometheus/alertmanager:v0.25.0 quay.io/prometheus/alertmanager:v0.25.0


## 10- on the operation server

scp /app/workspace/ceph/tools/cephadm root@mon1:/root/workspace


## 11- on first mon node

cd /root/workpspace
chmod +x cephadm
cp cephadm /usr/local/bin

apt install -y ceph-common


## 12- bootstrap new cluster

cephadm bootstrap --mon-ip <mon1-ip> \
--allow-fqdn-hostname \
--initial-dashboard-user admin \
--initial-dashboard-password 567tyuGHJbnm \
--dashboard-password-noupdate \
--skip-firewalld \
--with-centralized-logging \
--skip-pull


## 13- check cluster status

cephadm shell -- ceph -s
ceph status


## 14- create grafana config file and apply to cluster

cat <<EOF > grafana.yml
service_type: grafana
spec:
  initial_admin_password: 567tyuGHjbnm
EOF

ceph orch apply -i grafana.yml
ceph orch redeploy grafana


## 15- add hosts

ssh-copy-id -f -i /etc/ceph/ceph.pub root@<mon1>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<mon2>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<mon3>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<mon4>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<mon5>

ssh-copy-id -f -i /etc/ceph/ceph.pub root@<osd1>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<osd2>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<osd3>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<osd3>
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<osd5>

ceph orch host add <mon1> <ip> --labels _admin,mon,mgr
ceph orch host add <mon2> <ip> --labels _admin,mon,mgr
ceph orch host add <mon3> <ip> --labels _admin,mon,mgr
ceph orch host add <mon4> <ip> --labels _admin,mon,mgr
ceph orch host add <mon5> <ip> --labels _admin,mon,mgr

ceph orch host add <osd1> <ip> --labels osd,mds
ceph orch host add <osd2> <ip> --labels osd,mds
ceph orch host add <osd3> <ip> --labels osd,mds
ceph orch host add <osd4> <ip> --labels osd,mds
ceph orch host add <osd5> <ip> --labels osd,mds


## 16- create osd 

ceph orch daemon add osd <osd1>:/dev/sdc
ceph orch daemon add osd <osd1>:/dev/sdd

ceph orch daemon add osd <osd2>:/dev/sdc
ceph orch daemon add osd <osd2>:/dev/sdd

ceph orch daemon add osd <osd3>:/dev/sdc
ceph orch daemon add osd <osd3>:/dev/sdd

ceph orch daemon add osd <osd4>:/dev/sdc
ceph orch daemon add osd <osd4>:/dev/sdd

ceph orch daemon add osd <osd5>:/dev/sdc
ceph orch daemon add osd <osd5>:/dev/sdd


## 17- create pool and filesystem

ceph osd pool create k8s-<cluster-name>-cephfs-data
ceph osd pool create k8s-<cluster-name>-cephfs-metadata
ceph fs new k8s-<cluster-name>-fs k8s-<cluster-name>-cephfs-metadata k8s-<cluster-name>-cephfs-data
ceph fs subvolumegroup create k8s-<cluster-name>-fs k8s-<cluster-name>-svg


## 18- create user for k8s


user_name=k8s-pa-cluster-cephfs
fs_name=k8s-pa-cluster-fs
metadata_name=k8s-pa-cluster-cephfs-metadata
data_name=k8s-pa-cluster-cephfs-data
svg_name=k8s-pa-cluster-svg


ceph auth get-or-create client.$user_name \
  mgr "allow rw" \
  osd "allow rwx tag cephfs metadata=$metadata_name, allow rw tag cephfs data=$data_name" \
  mds "allow r fsname=$fs_name path=/volumes, allow rws fsname=$fs_name path=/volumes/$svg_name" \
  mon "allow r fsname=$fs_name"


## 19- os tuning profile

cat <<EOF > mon-tune-profile.yml
profile_name: mon-tune-profile
placement:
  hosts:
    - <mon1>
    - <mon2>
	  - <mon3>
	  - <mon4>
	  - <mon5>
settings:
  fs.file-max: 1000000
  vm.swappiness: '13'
EOF

ceph orch tuned-profile apply -i mon-tune-profile.yml
