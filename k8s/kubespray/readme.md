<p align="center" width="100%">
    <img width="15%" src="https://github.com/kubernetes/kubernetes/blob/master/logo/logo_with_border.png"> 
</p>

# Deploy a Production Ready Kubernetes Cluster with [Kubespray](https://github.com/kubernetes-sigs/kubespray/tree/master)

## Step 01: preparing os and servers


### update all k8s nodes

```
apt update
apt upgrade -y
```

### reboot nodes

```
reboot
```

### purge old files

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

### create passwordless sudoer user on all k8s nodes

```
useradd -m kubespray
passwd kubespray
usermod -s /bin/bash kubespray
echo 'kubespray ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/kubespray
```


## on the operation server


### create ssh-keygen

```
ssh-keygen
```

### install pip and venv

```
sudo apt install -y python3-pip python3.10-venv
```

### copy operation server pub key to all k8s nodes

```
ssh-copy-id kubespray@<cp1-ip>
ssh-copy-id kubespray@<cp2-ip>
ssh-copy-id kubespray@<cp3-ip>
ssh-copy-id kubespray@<cp4-ip>
ssh-copy-id kubespray@<cp5-ip>

ssh-copy-id kubespray@<wrkr1-ip>
ssh-copy-id kubespray@<wrkr2-ip>
ssh-copy-id kubespray@<wrkr3-ip>
ssh-copy-id kubespray@<wrkr4-ip>
```


## Step 02: get kubespray with specific tag:

```
# curl <github-repository>/kubernetes-sigs/kubespray/archive/refs/tags/v2.28.0.zip -o kubespray-2.28.0.zip
```

```
mkdir -p /root/workspace/k8s/<cluster-name>
cd /root/workspace/k8s/<cluster-name>
curl http://192.168.106.12:8081/repository/github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.28.0.zip \
-o kubespray-2.28.0.zip
unzip kubespray-2.28.0.zip
cd kubespray-2.28.0
```

## Step 03: installing ansible and change inventory file

```
python3 -m venv <cluster-name>-kubespray-venv
source <cluster-name>-kubespray-venv/bin/activate
```

```
# index-url = <pypi-repository>/simple
# trusted-host = <nexus-ip>
```

```
cat <<EOF > <cluster-name>-kubespray-venv/pip.conf
[global]
index-url = http://192.168.106.12:8081/repository/pypi.org/simple
trusted-host = 192.168.106.12
EOF
```

```
pip3 install -U -r requirements.txt
```

```
cp -rfp inventory/sample inventory/<cluster-name>
```

```
[kube_control_plane]
node1 ansible_host=<cp1-ip> etcd_member_name=etcd1
node2 ansible_host=<cp2-ip> etcd_member_name=etcd2
node3 ansible_host=<cp3-ip> etcd_member_name=etcd3
node4 ansible_host=<cp4-ip> etcd_member_name=etcd4
node5 ansible_host=<cp5-ip> etcd_member_name=etcd5

[etcd:children]
kube_control_plane

[kube_node]
node6 ansible_host=<wrkr1-ip>
```

## Step 04: change variable file: group_vars/all/all.yml

```
---
## Directory where the binaries will be installed
bin_dir: /usr/local/bin

## The access_ip variable is used to define how other nodes should access
## the node.  This is used in flannel to allow other flannel nodes to see
## this node for example.  The access_ip is really useful AWS and Google
## environments where the nodes are accessed remotely by the "public" ip,
## but don't know about that address themselves.
# access_ip: 1.1.1.1


## External LB example config
## apiserver_loadbalancer_domain_name: "elb.some.domain"
# loadbalancer_apiserver:
#   address: 1.2.3.4
#   port: 1234

## Internal loadbalancers for apiservers
loadbalancer_apiserver_localhost: true
# valid options are "nginx" or "haproxy"
loadbalancer_apiserver_type: nginx  # valid values "nginx" or "haproxy"

## Local loadbalancer should use this port
## And must be set port 6443
loadbalancer_apiserver_port: 6443

## If loadbalancer_apiserver_healthcheck_port variable defined, enables proxy liveness check for nginx.
loadbalancer_apiserver_healthcheck_port: 8081

### OTHER OPTIONAL VARIABLES

## By default, Kubespray collects nameservers on the host. It then adds the previously collected nameservers in nameserverentries.
## If true, Kubespray does not include host nameservers in nameserverentries in dns_late stage. However, It uses the nameserver to make sure cluster installed safely in dns_early stage.
## Use this option with caution, you may need to define your dns servers. Otherwise, the outbound queries such as www.google.com may fail.
# disable_host_nameservers: false

## Upstream dns servers
# upstream_dns_servers:
#   - 8.8.8.8
#   - 8.8.4.4

## There are some changes specific to the cloud providers
## for instance we need to encapsulate packets with some network plugins
## If set the possible values only 'external' after K8s v1.31.
# cloud_provider:

# External Cloud Controller Manager (Formerly known as cloud provider)
# cloud_provider must be "external", otherwise this setting is invalid.
# Supported external cloud controllers are: 'openstack', 'vsphere', 'oci', 'huaweicloud', 'hcloud' and 'manual'
# 'manual' does not install the cloud controller manager used by Kubespray.
# If you fill in a value other than the above, the check will fail.
# external_cloud_provider:

## Set these proxy values in order to update package manager and docker daemon to use proxies and custom CA for https_proxy if needed
# http_proxy: ""
# https_proxy: ""
# https_proxy_cert_file: ""

## Refer to roles/kubespray_defaults/defaults/main/main.yml before modifying no_proxy
# no_proxy: ""

## Some problems may occur when downloading files over https proxy due to ansible bug
## https://github.com/ansible/ansible/issues/32750. Set this variable to False to disable
## SSL validation of get_url module. Note that kubespray will still be performing checksum validation.
# download_validate_certs: False

## If you need exclude all cluster nodes from proxy and other resources, add other resources here.
# additional_no_proxy: ""

## If you need to disable proxying of os package repositories but are still behind an http_proxy set
## skip_http_proxy_on_os_packages to true
## This will cause kubespray not to set proxy environment in /etc/yum.conf for centos and in /etc/apt/apt.conf for debian/ubuntu
## Special information for debian/ubuntu - you have to set the no_proxy variable, then apt package will install from your source of wish
# skip_http_proxy_on_os_packages: false

## Since workers are included in the no_proxy variable by default, docker engine will be restarted on all nodes (all
## pods will restart) when adding or removing workers.  To override this behaviour by only including control plane nodes
## in the no_proxy variable, set below to true:
no_proxy_exclude_workers: false

## Certificate Management
## This setting determines whether certs are generated via scripts.
## Chose 'none' if you provide your own certificates.
## Option is  "script", "none"
# cert_management: script

## Set to true to allow pre-checks to fail and continue deployment
# ignore_assert_errors: false

## The read-only port for the Kubelet to serve on with no authentication/authorization. Uncomment to enable.
# kube_read_only_port: 10255

## Set true to download and cache container
download_container: true

## Deploy container engine
# Set false if you want to deploy container engine manually.
deploy_container_engine: true

## Red Hat Enterprise Linux subscription registration
## Add either RHEL subscription Username/Password or Organization ID/Activation Key combination
## Update RHEL subscription purpose usage, role and SLA if necessary
# rh_subscription_username: ""
# rh_subscription_password: ""
# rh_subscription_org_id: ""
# rh_subscription_activation_key: ""
# rh_subscription_usage: "Development"
# rh_subscription_role: "Red Hat Enterprise Server"
# rh_subscription_sla: "Self-Support"

## Check if access_ip responds to ping. Set false if your firewall blocks ICMP.
# ping_access_ip: true

# sysctl_file_path to add sysctl conf to
sysctl_file_path: "/etc/sysctl.d/99-sysctl.conf"

## Variables for webhook token auth https://kubernetes.io/docs/reference/access-authn-authz/authentication/#webhook-token-authentication
kube_webhook_token_auth: false
kube_webhook_token_auth_url_skip_tls_verify: false
# kube_webhook_token_auth_url: https://...
## base64-encoded string of the webhook's CA certificate
# kube_webhook_token_auth_ca_data: "LS0t..."

## NTP Settings
# Start the ntpd or chrony service and enable it at system boot.
ntp_enabled: false
ntp_manage_config: false
ntp_servers:
  - "0.pool.ntp.org iburst"
  - "1.pool.ntp.org iburst"
  - "2.pool.ntp.org iburst"
  - "3.pool.ntp.org iburst"

## Used to control no_log attribute
unsafe_show_logs: false

## If enabled it will allow kubespray to attempt setup even if the distribution is not supported. For unsupported distributions this can lead to unexpected failures in some cases.
allow_unsupported_distribution_setup: false
```

## Step 05: change variable file: group_vars/all/containerd.yml

```
# Registries defined within containerd.

# containerd_registries_mirrors:
#  - prefix: docker.io
#    mirrors:
#      - host: <docker-repository>
#        capabilities: ["pull", "resolve"]
#  - prefix: registry.k8s.io
#    mirrors:
#      - host: <k8s-repository>
#        capabilities: ["pull", "resolve"]
#  - prefix: quay.io
#    mirrors:
#      - host: <quay-repository>
#        capabilities: ["pull", "resolve"]
```


```
---
# Please see roles/container-engine/containerd/defaults/main.yml for more configuration options

# containerd_storage_dir: "/var/lib/containerd"
# containerd_state_dir: "/run/containerd"
# containerd_oom_score: 0

# containerd_default_runtime: "runc"
# containerd_snapshotter: "native"

# containerd_runc_runtime:
#   name: runc
#   type: "io.containerd.runc.v2"
#   engine: ""
#   root: ""

# containerd_additional_runtimes:
# Example for Kata Containers as additional runtime:
#   - name: kata
#     type: "io.containerd.kata.v2"
#     engine: ""
#     root: ""

# containerd_grpc_max_recv_message_size: 16777216
# containerd_grpc_max_send_message_size: 16777216

# Containerd debug socket location: unix or tcp format
# containerd_debug_address: ""

# Containerd log level
# containerd_debug_level: "info"

# Containerd logs format, supported values: text, json
# containerd_debug_format: ""

# Containerd debug socket UID
# containerd_debug_uid: 0

# Containerd debug socket GID
# containerd_debug_gid: 0

# containerd_metrics_address: ""

# containerd_metrics_grpc_histogram: false

# Registries defined within containerd.

containerd_registries_mirrors:
  - prefix: docker.io
    mirrors:
      - host: http://192.168.106.12:8082
        capabilities: ["pull", "resolve"]
  - prefix: registry.k8s.io
    mirrors:
      - host: http://192.168.106.12:8084
        capabilities: ["pull", "resolve"]
  - prefix: quay.io
    mirrors:
      - host: http://192.168.106.12:8083
        capabilities: ["pull", "resolve"]

# containerd_max_container_log_line_size: 16384

# containerd_registry_auth:
#   - registry: 10.0.0.2:5000
#     username: user
#     password: pass
```

## Step 06: change variable file: group_vars/all/etcd.yml

```
---
## Directory where etcd data stored
etcd_data_dir: /var/lib/etcd

## Container runtime
## docker for docker, crio for cri-o and containerd for containerd.
## Additionally you can set this to kubeadm if you want to install etcd using kubeadm
## Kubeadm etcd deployment is experimental and only available for new deployments
## If this is not set, container manager will be inherited from the Kubespray defaults
## and not from k8s_cluster/k8s-cluster.yml, which might not be what you want.
## Also this makes possible to use different container manager for etcd nodes.
container_manager: containerd

## Settings for etcd deployment type
# Set this to docker if you are using container_manager: docker
etcd_deployment_type: kubeadm
etcd_metrics_port: 2381
etcd_listen_metrics_urls: "http://0.0.0.0:2381"
```

## Step 07: change variable file: group_vars/all/offline.yml

```
---
## Global Offline settings
### Private Container Image Registry
# registry_host: "myprivateregisry.com"

# files_repo: "http://myprivatehttpd"
files_repo: "http://192.168.106.12:8081/repository"

### If using CentOS, RedHat, AlmaLinux or Fedora
# yum_repo: "http://myinternalyumrepo"
### If using Debian
# debian_repo: "http://myinternaldebianrepo"
### If using Ubuntu
# ubuntu_repo: "http://myinternalubunturepo"

## Container Registry overrides
# kube_image_repo: "{{ registry_host }}"
# gcr_image_repo: "{{ registry_host }}"
# github_image_repo: "{{ registry_host }}"
# docker_image_repo: "{{ registry_host }}"
# quay_image_repo: "{{ registry_host }}"


## Kubernetes components
kubeadm_download_url: "{{ k8s_files_repo }}/dl.k8s.io/release/v{{ kube_version }}/bin/linux/{{ image_arch }}/kubeadm"
kubectl_download_url: "{{ k8s_files_repo }}/dl.k8s.io/release/v{{ kube_version }}/bin/linux/{{ image_arch }}/kubectl"
kubelet_download_url: "{{ k8s_files_repo }}/dl.k8s.io/release/v{{ kube_version }}/bin/linux/{{ image_arch }}/kubelet"


## Two options - Override entire repository or override only a single binary.

## [Optional] 1 - Override entire binary repository
# github_url: "https://my_github_proxy"
# dl_k8s_io_url: "https://my_dl_k8s_io_proxy"
# storage_googleapis_url: "https://my_storage_googleapi_proxy"
# get_helm_url: "https://my_helm_sh_proxy"

## [Optional] 2 - Override a specific binary
## CNI Plugins
cni_download_url: "{{ files_repo }}/github.com/containernetworking/plugins/releases/download/v{{ cni_version }}/cni-plugins-linux-{{ image_arch }}-v{{ cni_version }}.tgz"

## cri-tools
crictl_download_url: "{{ files_repo }}/github.com/kubernetes-sigs/cri-tools/releases/download/v{{ crictl_version }}/crictl-v{{ crictl_version }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz"

## [Optional] etcd: only if you use etcd_deployment=host
etcd_download_url: "{{ files_repo }}/github.com/etcd-io/etcd/releases/download/v{{ etcd_version }}/etcd-v{{ etcd_version }}-linux-{{ image_arch }}.tar.gz"

# [Optional] Calico: If using Calico network plugin
calicoctl_download_url: "{{ files_repo }}/github.com/projectcalico/calico/releases/download/v{{ calico_ctl_version }}/calicoctl-linux-{{ image_arch }}"
# [Optional] Calico with kdd: If using Calico network plugin with kdd datastore
calico_crds_download_url: "{{ files_repo }}/github.com/projectcalico/calico/archive/v{{ calico_version }}.tar.gz"

# [Optional] Cilium: If using Cilium network plugin
# ciliumcli_download_url: "{{ files_repo }}/github.com/cilium/cilium-cli/releases/download/v{{ cilium_cli_version }}/cilium-linux-{{ image_arch }}.tar.gz"

# [Optional] helm: only if you set helm_enabled: true
helm_download_url: "{{ files_repo }}/get.helm.sh/helm-v{{ helm_version }}-linux-{{ image_arch }}.tar.gz"

# [Optional] crun: only if you set crun_enabled: true
# crun_download_url: "{{ files_repo }}/github.com/containers/crun/releases/download/{{ crun_version }}/crun-{{ crun_version }}-linux-{{ image_arch }}"

# [Optional] kata: only if you set kata_containers_enabled: true
# kata_containers_download_url: "{{ files_repo }}/github.com/kata-containers/kata-containers/releases/download/{{ kata_containers_version }}/kata-static-{{ kata_containers_version }}-{{ image_arch }}.tar.xz"

# [Optional] cri-dockerd: only if you set container_manager: docker
# cri_dockerd_download_url: "{{ files_repo }}/github.com/Mirantis/cri-dockerd/releases/download/v{{ cri_dockerd_version }}/cri-dockerd-{{ cri_dockerd_version }}.{{ image_arch }}.tgz"

# [Optional] runc: if you set container_manager to containerd or crio
runc_download_url: "{{ files_repo }}/github.com/opencontainers/runc/releases/download/v{{ runc_version }}/runc.{{ image_arch }}"

# [Optional] cri-o: only if you set container_manager: crio
# crio_download_base: "download.opensuse.org/repositories/devel:kubic:libcontainers:stable"
# crio_download_crio: "http://{{ crio_download_base }}:/cri-o:/"
# crio_download_url: "{{ files_repo }}/storage.googleapis.com/cri-o/artifacts/cri-o.{{ image_arch }}.v{{ crio_version }}.tar.gz"
# skopeo_download_url: "{{ files_repo }}/github.com/lework/skopeo-binary/releases/download/v{{ skopeo_version }}/skopeo-linux-{{ image_arch }}"

# [Optional] containerd: only if you set container_runtime: containerd
containerd_download_url: "{{ files_repo }}/github.com/containerd/containerd/releases/download/v{{ containerd_version }}/containerd-{{ containerd_version }}-linux-{{ image_arch }}.tar.gz"
nerdctl_download_url: "{{ files_repo }}/github.com/containerd/nerdctl/releases/download/v{{ nerdctl_version }}/nerdctl-{{ nerdctl_version }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz"

# [Optional] runsc,containerd-shim-runsc: only if you set gvisor_enabled: true
# gvisor_runsc_download_url: "{{ files_repo }}/storage.googleapis.com/gvisor/releases/release/{{ gvisor_version }}/{{ ansible_architecture }}/runsc"
# gvisor_containerd_shim_runsc_download_url: "{{ files_repo }}/storage.googleapis.com/gvisor/releases/release/{{ gvisor_version }}/{{ ansible_architecture }}/containerd-shim-runsc-v1"


## CentOS/Redhat/AlmaLinux
### For EL8, baseos and appstream must be available,
### By default we enable those repo automatically
# rhel_enable_repos: false
### Docker / Containerd
# docker_rh_repo_base_url: "{{ yum_repo }}/docker-ce/$releasever/$basearch"
# docker_rh_repo_gpgkey: "{{ yum_repo }}/docker-ce/gpg"

## Fedora
### Docker
# docker_fedora_repo_base_url: "{{ yum_repo }}/docker-ce/{{ ansible_distribution_major_version }}/{{ ansible_architecture }}"
# docker_fedora_repo_gpgkey: "{{ yum_repo }}/docker-ce/gpg"
### Containerd
# containerd_fedora_repo_base_url: "{{ yum_repo }}/containerd"
# containerd_fedora_repo_gpgkey: "{{ yum_repo }}/docker-ce/gpg"

## Debian
### Docker
# docker_debian_repo_base_url: "{{ debian_repo }}/docker-ce"
# docker_debian_repo_gpgkey: "{{ debian_repo }}/docker-ce/gpg"
### Containerd
# containerd_debian_repo_base_url: "{{ debian_repo }}/containerd"
# containerd_debian_repo_gpgkey: "{{ debian_repo }}/containerd/gpg"
# containerd_debian_repo_repokey: 'YOURREPOKEY'

## Ubuntu
### Docker
# docker_ubuntu_repo_base_url: "{{ ubuntu_repo }}/docker-ce"
# docker_ubuntu_repo_gpgkey: "{{ ubuntu_repo }}/docker-ce/gpg"
### Containerd
# containerd_ubuntu_repo_base_url: "{{ ubuntu_repo }}/containerd"
# containerd_ubuntu_repo_gpgkey: "{{ ubuntu_repo }}/containerd/gpg"
# containerd_ubuntu_repo_repokey: 'YOURREPOKEY'
```

## Step 08: change variable file: group_vars/k8s_cluster/addons.yml

```
---
# Kubernetes dashboard
# RBAC required. see docs/getting-started.md for access details.
# dashboard_enabled: false

# Helm deployment
helm_enabled: true

# Registry deployment
registry_enabled: false
# registry_namespace: kube-system
# registry_storage_class: ""
# registry_disk_size: "10Gi"

# Metrics Server deployment
metrics_server_enabled: true
metrics_server_container_port: 10250
metrics_server_kubelet_insecure_tls: true
metrics_server_metric_resolution: 15s
# metrics_server_kubelet_preferred_address_types: "InternalIP,ExternalIP,Hostname"
# metrics_server_host_network: false
metrics_server_replicas: 1

# Rancher Local Path Provisioner
local_path_provisioner_enabled: false
# local_path_provisioner_namespace: "local-path-storage"
# local_path_provisioner_storage_class: "local-path"
# local_path_provisioner_reclaim_policy: Delete
# local_path_provisioner_claim_root: /opt/local-path-provisioner/
# local_path_provisioner_debug: false
# local_path_provisioner_image_repo: "{{ docker_image_repo }}/rancher/local-path-provisioner"
# local_path_provisioner_image_tag: "v0.0.24"
# local_path_provisioner_helper_image_repo: "busybox"
# local_path_provisioner_helper_image_tag: "latest"

# Local volume provisioner deployment
local_volume_provisioner_enabled: false
# local_volume_provisioner_namespace: kube-system
# local_volume_provisioner_nodelabels:
#   - kubernetes.io/hostname
#   - topology.kubernetes.io/region
#   - topology.kubernetes.io/zone
# local_volume_provisioner_storage_classes:
#   local-storage:
#     host_dir: /mnt/disks
#     mount_dir: /mnt/disks
#     volume_mode: Filesystem
#     fs_type: ext4
#   fast-disks:
#     host_dir: /mnt/fast-disks
#     mount_dir: /mnt/fast-disks
#     block_cleaner_command:
#       - "/scripts/shred.sh"
#       - "2"
#     volume_mode: Filesystem
#     fs_type: ext4
# local_volume_provisioner_tolerations:
#   - effect: NoSchedule
#     operator: Exists

# CSI Volume Snapshot Controller deployment, set this to true if your CSI is able to manage snapshots
# currently, setting cinder_csi_enabled=true would automatically enable the snapshot controller
# Longhorn is an external CSI that would also require setting this to true but it is not included in kubespray
# csi_snapshot_controller_enabled: false
# csi snapshot namespace
# snapshot_controller_namespace: kube-system

# Gateway API CRDs
gateway_api_enabled: false

# Nginx ingress controller deployment
ingress_nginx_enabled: false
# ingress_nginx_host_network: false
# ingress_nginx_service_type: LoadBalancer
# ingress_nginx_service_annotations:
#   example.io/loadbalancerIPs: 1.2.3.4
# ingress_nginx_service_nodeport_http: 30080
# ingress_nginx_service_nodeport_https: 30081
ingress_publish_status_address: ""
# ingress_nginx_nodeselector:
#   kubernetes.io/os: "linux"
# ingress_nginx_tolerations:
#   - key: "node-role.kubernetes.io/control-plane"
#     operator: "Equal"
#     value: ""
#     effect: "NoSchedule"
# ingress_nginx_namespace: "ingress-nginx"
# ingress_nginx_insecure_port: 80
# ingress_nginx_secure_port: 443
# ingress_nginx_configmap:
#   map-hash-bucket-size: "128"
#   ssl-protocols: "TLSv1.2 TLSv1.3"
# ingress_nginx_configmap_tcp_services:
#   9000: "default/example-go:8080"
# ingress_nginx_configmap_udp_services:
#   53: "kube-system/coredns:53"
# ingress_nginx_extra_args:
#   - --default-ssl-certificate=default/foo-tls
# ingress_nginx_termination_grace_period_seconds: 300
# ingress_nginx_class: nginx
# ingress_nginx_without_class: true
# ingress_nginx_default: false

# ALB ingress controller deployment
ingress_alb_enabled: false
# alb_ingress_aws_region: "us-east-1"
# alb_ingress_restrict_scheme: "false"
# Enables logging on all outbound requests sent to the AWS API.
# If logging is desired, set to true.
# alb_ingress_aws_debug: "false"

# Cert manager deployment
cert_manager_enabled: false
# cert_manager_namespace: "cert-manager"
# cert_manager_tolerations:
#   - key: node-role.kubernetes.io/control-plane
#     effect: NoSchedule
# cert_manager_affinity:
#  nodeAffinity:
#    preferredDuringSchedulingIgnoredDuringExecution:
#    - weight: 100
#      preference:
#        matchExpressions:
#        - key: node-role.kubernetes.io/control-plane
#          operator: In
#          values:
#          - ""
# cert_manager_nodeselector:
#   kubernetes.io/os: "linux"

# cert_manager_trusted_internal_ca: |
#   -----BEGIN CERTIFICATE-----
#   [REPLACE with your CA certificate]
#   -----END CERTIFICATE-----
# cert_manager_leader_election_namespace: kube-system

# cert_manager_dns_policy: "ClusterFirst"
# cert_manager_dns_config:
#   nameservers:
#     - "1.1.1.1"
#     - "8.8.8.8"

# cert_manager_controller_extra_args:
#   - "--dns01-recursive-nameservers-only=true"
#   - "--dns01-recursive-nameservers=1.1.1.1:53,8.8.8.8:53"

# MetalLB deployment
metallb_enabled: false
metallb_speaker_enabled: "{{ metallb_enabled }}"
metallb_namespace: "metallb-system"
# metallb_protocol: "layer2"
# metallb_port: "7472"
# metallb_memberlist_port: "7946"
# metallb_config:
#   speaker:
#     nodeselector:
#       kubernetes.io/os: "linux"
#     tolerations:
#       - key: "node-role.kubernetes.io/control-plane"
#         operator: "Equal"
#         value: ""
#         effect: "NoSchedule"
#   controller:
#     nodeselector:
#       kubernetes.io/os: "linux"
#     tolerations:
#       - key: "node-role.kubernetes.io/control-plane"
#         operator: "Equal"
#         value: ""
#         effect: "NoSchedule"
#   address_pools:
#     primary:
#       ip_range:
#         - 10.5.0.0/16
#       auto_assign: true
#     pool1:
#       ip_range:
#         - 10.6.0.0/16
#       auto_assign: true
#     pool2:
#       ip_range:
#         - 10.10.0.0/16
#       auto_assign: true
#   layer2:
#     - primary
#   layer3:
#     defaults:
#       peer_port: 179
#       hold_time: 120s
#     communities:
#       vpn-only: "1234:1"
#       NO_ADVERTISE: "65535:65282"
#     metallb_peers:
#         peer1:
#           peer_address: 10.6.0.1
#           peer_asn: 64512
#           my_asn: 4200000000
#           communities:
#             - vpn-only
#           address_pool:
#             - pool1
#         peer2:
#           peer_address: 10.10.0.1
#           peer_asn: 64513
#           my_asn: 4200000000
#           communities:
#             - NO_ADVERTISE
#           address_pool:
#             - pool2

argocd_enabled: false
# argocd_namespace: argocd
# Default password:
#   - https://argo-cd.readthedocs.io/en/stable/getting_started/#4-login-using-the-cli
#   ---
#   The initial password is autogenerated and stored in `argocd-initial-admin-secret` in the argocd namespace defined above.
#   Using the argocd CLI the generated password can be automatically be fetched from the current kubectl context with the command:
#   argocd admin initial-password -n argocd
#   ---
# Use the following var to set admin password
# argocd_admin_password: "password"

# The plugin manager for kubectl

# Kube VIP
kube_vip_enabled: false
# kube_vip_arp_enabled: true
# kube_vip_controlplane_enabled: true
# kube_vip_address: 192.168.56.120
# loadbalancer_apiserver:
#   address: "{{ kube_vip_address }}"
#   port: 6443
# kube_vip_interface: eth0
# kube_vip_services_enabled: false
# kube_vip_dns_mode: first
# kube_vip_cp_detect: false
# kube_vip_leasename: plndr-cp-lock
# kube_vip_enable_node_labeling: false
# kube_vip_lb_fwdmethod: local

# Node Feature Discovery
node_feature_discovery_enabled: false
# node_feature_discovery_gc_sa_name: node-feature-discovery
# node_feature_discovery_gc_sa_create: false
# node_feature_discovery_worker_sa_name: node-feature-discovery
# node_feature_discovery_worker_sa_create: false
# node_feature_discovery_master_config:
#   extraLabelNs: ["nvidia.com"]
```

## Step 09: change variable file: group_vars/k8s_cluster/k8s-cluster.yml

```
---
# Kubernetes configuration dirs and system namespace.
# Those are where all the additional config stuff goes
# the kubernetes normally puts in /srv/kubernetes.
# This puts them in a sane location and namespace.
# Editing those values will almost surely break something.
kube_config_dir: /etc/kubernetes
kube_script_dir: "{{ bin_dir }}/kubernetes-scripts"
kube_manifest_dir: "{{ kube_config_dir }}/manifests"

# This is where all the cert scripts and certs will be located
kube_cert_dir: "{{ kube_config_dir }}/ssl"

# This is where all of the bearer tokens will be stored
kube_token_dir: "{{ kube_config_dir }}/tokens"

kube_api_anonymous_auth: true

# Where the binaries will be downloaded.
# Note: ensure that you've enough disk space (about 1G)
local_release_dir: "/tmp/releases"
# Random shifts for retrying failed ops like pushing/downloading
retry_stagger: 5

# This is the user that owns tha cluster installation.
kube_owner: kube

# This is the group that the cert creation scripts chgrp the
# cert files to. Not really changeable...
kube_cert_group: kube-cert

# Cluster Loglevel configuration
kube_log_level: 2

# Directory where credentials will be stored
credentials_dir: "{{ inventory_dir }}/credentials"

## It is possible to activate / deactivate selected authentication methods (oidc, static token auth)
# kube_oidc_auth: false
# kube_token_auth: false


## Variables for OpenID Connect Configuration https://kubernetes.io/docs/admin/authentication/
## To use OpenID you have to deploy additional an OpenID Provider (e.g Dex, Keycloak, ...)

# kube_oidc_url: https:// ...
# kube_oidc_client_id: kubernetes
## Optional settings for OIDC
# kube_oidc_ca_file: "{{ kube_cert_dir }}/ca.pem"
# kube_oidc_username_claim: sub
# kube_oidc_username_prefix: 'oidc:'
# kube_oidc_groups_claim: groups
# kube_oidc_groups_prefix: 'oidc:'

## Variables to control webhook authn/authz
# kube_webhook_token_auth: false
# kube_webhook_token_auth_url: https://...
# kube_webhook_token_auth_url_skip_tls_verify: false

## For webhook authorization, authorization_modes must include Webhook or kube_apiserver_authorization_config_authorizers must configure a type: Webhook
# kube_webhook_authorization: false
# kube_webhook_authorization_url: https://...
# kube_webhook_authorization_url_skip_tls_verify: false

# Choose network plugin (cilium, calico, kube-ovn, weave or flannel. Use cni for generic cni plugin)
# Can also be set to 'cloud', which lets the cloud provider setup appropriate routing
kube_network_plugin: calico

# Setting multi_networking to true will install Multus: https://github.com/k8snetworkplumbingwg/multus-cni
kube_network_plugin_multus: false

# Kubernetes internal network for services, unused block of space.
kube_service_addresses: 10.233.0.0/18

# internal network. When used, it will assign IP
# addresses from this range to individual pods.
# This network must be unused in your network infrastructure!
kube_pods_subnet: 10.233.64.0/18

# internal network node size allocation (optional). This is the size allocated
# to each node for pod IP address allocation. Note that the number of pods per node is
# also limited by the kubelet_max_pods variable which defaults to 110.
#
# Example:
# Up to 64 nodes and up to 254 or kubelet_max_pods (the lowest of the two) pods per node:
#  - kube_pods_subnet: 10.233.64.0/18
#  - kube_network_node_prefix: 24
#  - kubelet_max_pods: 110
#
# Example:
# Up to 128 nodes and up to 126 or kubelet_max_pods (the lowest of the two) pods per node:
#  - kube_pods_subnet: 10.233.64.0/18
#  - kube_network_node_prefix: 25
#  - kubelet_max_pods: 110
kube_network_node_prefix: 24

# Kubernetes internal network for IPv6 services, unused block of space.
# This is only used if ipv6_stack is set to true
# This provides 4096 IPv6 IPs
kube_service_addresses_ipv6: fd85:ee78:d8a6:8607::1000/116

# Internal network. When used, it will assign IPv6 addresses from this range to individual pods.
# This network must not already be in your network infrastructure!
# This is only used if ipv6_stack is set to true.
# This provides room for 256 nodes with 254 pods per node.
kube_pods_subnet_ipv6: fd85:ee78:d8a6:8607::1:0000/112

# IPv6 subnet size allocated to each for pods.
# This is only used if ipv6_stack is set to true
# This provides room for 254 pods per node.
kube_network_node_prefix_ipv6: 120

# The port the API Server will be listening on.
kube_apiserver_ip: "{{ kube_service_subnets.split(',') | first | ansible.utils.ipaddr('net') | ansible.utils.ipaddr(1) | ansible.utils.ipaddr('address') }}"
kube_apiserver_port: 6443  # (https)

# Kube-proxy proxyMode configuration.
# Can be ipvs, iptables, nftables
# TODO: it needs to be changed to nftables when the upstream use nftables as default
kube_proxy_mode: ipvs

# configure arp_ignore and arp_announce to avoid answering ARP queries from kube-ipvs0 interface
# must be set to true for MetalLB, kube-vip(ARP enabled) to work
kube_proxy_strict_arp: false

# A string slice of values which specify the addresses to use for NodePorts.
# Values may be valid IP blocks (e.g. 1.2.3.0/24, 1.2.3.4/32).
# The default empty string slice ([]) means to use all local addresses.
# kube_proxy_nodeport_addresses_cidr is retained for legacy config
kube_proxy_nodeport_addresses: >-
  {%- if kube_proxy_nodeport_addresses_cidr is defined -%}
  [{{ kube_proxy_nodeport_addresses_cidr }}]
  {%- else -%}
  []
  {%- endif -%}

# If non-empty, will use this string as identification instead of the actual hostname
# kube_override_hostname: {{ inventory_hostname }}

## Encrypting Secret Data at Rest
kube_encrypt_secret_data: false

# Graceful Node Shutdown (Kubernetes >= 1.21.0), see https://kubernetes.io/blog/2021/04/21/graceful-node-shutdown-beta/
# kubelet_shutdown_grace_period had to be greater than kubelet_shutdown_grace_period_critical_pods to allow
# non-critical podsa to also terminate gracefully
# kubelet_shutdown_grace_period: 60s
# kubelet_shutdown_grace_period_critical_pods: 20s

# DNS configuration.
# Kubernetes cluster name, also will be used as DNS domain
cluster_name: cluster.local
# Subdomains of DNS domain to be resolved via /etc/resolv.conf for hostnet pods
ndots: 2
# dns_timeout: 2
# dns_attempts: 2
# Custom search domains to be added in addition to the default cluster search domains
# searchdomains:
#   - svc.{{ cluster_name }}
#   - default.svc.{{ cluster_name }}
# Remove default cluster search domains (``default.svc.{{ dns_domain }}, svc.{{ dns_domain }}``).
# remove_default_searchdomains: false
# Can be coredns, coredns_dual, manual or none
dns_mode: coredns
# Set manual server if using a custom cluster DNS server
# manual_dns_server: 10.x.x.x
# Enable nodelocal dns cache
enable_nodelocaldns: true
enable_nodelocaldns_secondary: false
nodelocaldns_ip: 169.254.25.10
nodelocaldns_health_port: 9254
nodelocaldns_second_health_port: 9256
nodelocaldns_bind_metrics_host_ip: false
nodelocaldns_secondary_skew_seconds: 5
# nodelocaldns_external_zones:
# - zones:
#   - example.com
#   - example.io:1053
#   nameservers:
#   - 1.1.1.1
#   - 2.2.2.2
#   cache: 5
# - zones:
#   - https://mycompany.local:4453
#   nameservers:
#   - 192.168.0.53
#   cache: 0
# - zones:
#   - mydomain.tld
#   nameservers:
#   - 10.233.0.3
#   cache: 5
#   rewrite:
#   - name website.tld website.namespace.svc.cluster.local
# Enable k8s_external plugin for CoreDNS
enable_coredns_k8s_external: false
coredns_k8s_external_zone: k8s_external.local
# Enable endpoint_pod_names option for kubernetes plugin
enable_coredns_k8s_endpoint_pod_names: false
# Set forward options for upstream DNS servers in coredns (and nodelocaldns) config
# dns_upstream_forward_extra_opts:
#   policy: sequential
# Apply extra options to coredns kubernetes plugin
# coredns_kubernetes_extra_opts:
#   - 'fallthrough example.local'
# Forward extra domains to the coredns kubernetes plugin
# coredns_kubernetes_extra_domains: ''

# Can be docker_dns, host_resolvconf or none
resolvconf_mode: host_resolvconf
# Deploy netchecker app to verify DNS resolve as an HTTP service
deploy_netchecker: false
# Ip address of the kubernetes skydns service
skydns_server: "{{ kube_service_subnets.split(',') | first | ansible.utils.ipaddr('net') | ansible.utils.ipaddr(3) | ansible.utils.ipaddr('address') }}"
skydns_server_secondary: "{{ kube_service_subnets.split(',') | first | ansible.utils.ipaddr('net') | ansible.utils.ipaddr(4) | ansible.utils.ipaddr('address') }}"
dns_domain: "{{ cluster_name }}"

## Container runtime
## docker for docker, crio for cri-o and containerd for containerd.
## Default: containerd
container_manager: containerd

# Additional container runtimes
kata_containers_enabled: false

kubeadm_certificate_key: "{{ lookup('password', credentials_dir + '/kubeadm_certificate_key.creds length=64 chars=hexdigits') | lower }}"

# K8s image pull policy (imagePullPolicy)
k8s_image_pull_policy: IfNotPresent

# audit log for kubernetes
kubernetes_audit: true

# define kubelet config dir for dynamic kubelet
# kubelet_config_dir:
default_kubelet_config_dir: "{{ kube_config_dir }}/dynamic_kubelet_dir"

# Make a copy of kubeconfig on the host that runs Ansible in {{ inventory_dir }}/artifacts
# kubeconfig_localhost: true
# Use ansible_host as external api ip when copying over kubeconfig.
# kubeconfig_localhost_ansible_host: false
# Download kubectl onto the host that runs Ansible in {{ bin_dir }}
# kubectl_localhost: false

# A comma separated list of levels of node allocatable enforcement to be enforced by kubelet.
# Acceptable options are 'pods', 'system-reserved', 'kube-reserved' and ''. Default is "".
# kubelet_enforce_node_allocatable: pods

## Set runtime and kubelet cgroups when using systemd as cgroup driver (default)
# kubelet_runtime_cgroups: "/{{ kube_service_cgroups }}/{{ container_manager }}.service"
# kubelet_kubelet_cgroups: "/{{ kube_service_cgroups }}/kubelet.service"

## Set runtime and kubelet cgroups when using cgroupfs as cgroup driver
# kubelet_runtime_cgroups_cgroupfs: "/system.slice/{{ container_manager }}.service"
# kubelet_kubelet_cgroups_cgroupfs: "/system.slice/kubelet.service"

# Whether to run kubelet and container-engine daemons in a dedicated cgroup.
kube_reserved: true
## Uncomment to override default values
## The following two items need to be set when kube_reserved is true
# kube_reserved_cgroups_for_service_slice: kube.slice
# kube_reserved_cgroups: "/{{ kube_reserved_cgroups_for_service_slice }}"
kube_memory_reserved: 256Mi
kube_cpu_reserved: 100m
kube_ephemeral_storage_reserved: 2Gi
kube_pid_reserved: "1000"

## Optionally reserve resources for OS system daemons.
system_reserved: true
## Uncomment to override default values
## The following two items need to be set when system_reserved is true
# system_reserved_cgroups_for_service_slice: system.slice
# system_reserved_cgroups: "/{{ system_reserved_cgroups_for_service_slice }}"
system_memory_reserved: 512Mi
system_cpu_reserved: 500m
system_ephemeral_storage_reserved: 2Gi

## Eviction Thresholds to avoid system OOMs
# https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/#eviction-thresholds
# eviction_hard: {}
# eviction_hard_control_plane: {}

# An alternative flexvolume plugin directory
# kubelet_flexvolumes_plugins_dir: /usr/libexec/kubernetes/kubelet-plugins/volume/exec

## Supplementary addresses that can be added in kubernetes ssl keys.
## That can be useful for example to setup a keepalived virtual IP
# supplementary_addresses_in_ssl_keys: [10.0.0.1, 10.0.0.2, 10.0.0.3]

## Running on top of openstack vms with cinder enabled may lead to unschedulable pods due to NoVolumeZoneConflict restriction in kube-scheduler.
## See https://github.com/kubernetes-sigs/kubespray/issues/2141
## Set this variable to true to get rid of this issue
volume_cross_zone_attachment: false
## Add Persistent Volumes Storage Class for corresponding cloud provider (supported: in-tree OpenStack, Cinder CSI,
## AWS EBS CSI, Azure Disk CSI, GCP Persistent Disk CSI)
persistent_volumes_enabled: false

## Container Engine Acceleration
## Enable container acceleration feature, for example use gpu acceleration in containers
# nvidia_accelerator_enabled: true
## Nvidia GPU driver install. Install will by done by a (init) pod running as a daemonset.
## Important: if you use Ubuntu then you should set in all.yml 'docker_storage_options: -s overlay2'
## Array with nvida_gpu_nodes, leave empty or comment if you don't want to install drivers.
## Labels and taints won't be set to nodes if they are not in the array.
# nvidia_gpu_nodes:
#   - kube-gpu-001
# nvidia_driver_version: "384.111"
## flavor can be tesla or gtx
# nvidia_gpu_flavor: gtx
## NVIDIA driver installer images. Change them if you have trouble accessing gcr.io.
# nvidia_driver_install_centos_container: atzedevries/nvidia-centos-driver-installer:2
# nvidia_driver_install_ubuntu_container: gcr.io/google-containers/ubuntu-nvidia-driver-installer@sha256:7df76a0f0a17294e86f691c81de6bbb7c04a1b4b3d4ea4e7e2cccdc42e1f6d63
## NVIDIA GPU device plugin image.
# nvidia_gpu_device_plugin_container: "registry.k8s.io/nvidia-gpu-device-plugin@sha256:0842734032018be107fa2490c98156992911e3e1f2a21e059ff0105b07dd8e9e"

## Support tls min version, Possible values: VersionTLS10, VersionTLS11, VersionTLS12, VersionTLS13.
# tls_min_version: "VersionTLS12"

## Support tls cipher suites.
# tls_cipher_suites: {}
#   - TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA
#   - TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256
#   - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
#   - TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA
#   - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
#   - TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
#   - TLS_ECDHE_ECDSA_WITH_RC4_128_SHA
#   - TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
#   - TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
#   - TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256
#   - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
#   - TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
#   - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
#   - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
#   - TLS_ECDHE_RSA_WITH_RC4_128_SHA
#   - TLS_RSA_WITH_3DES_EDE_CBC_SHA
#   - TLS_RSA_WITH_AES_128_CBC_SHA
#   - TLS_RSA_WITH_AES_128_CBC_SHA256
#   - TLS_RSA_WITH_AES_128_GCM_SHA256
#   - TLS_RSA_WITH_AES_256_CBC_SHA
#   - TLS_RSA_WITH_AES_256_GCM_SHA384
#   - TLS_RSA_WITH_RC4_128_SHA

## Amount of time to retain events. (default 1h0m0s)
event_ttl_duration: "1h0m0s"

## Automatically renew K8S control plane certificates on first Monday of each month
auto_renew_certificates: true
# First Monday of each month
auto_renew_certificates_systemd_calendar: "Mon *-*-1,2,3,4,5,6,7 03:{{ groups['kube_control_plane'].index(inventory_hostname) }}0:00"

kubeadm_patches_dir: "{{ kube_config_dir }}/patches"
kubeadm_patches: []
# See https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/#patches
# Correspondance with this link
# patchtype = type
# target = target
# suffix -> managed automatically
# extension -> always "yaml"
# kubeadm_patches:
# - target: kube-apiserver|kube-controller-manager|kube-scheduler|etcd|kubeletconfiguration
#   type: strategic(default)|json|merge
#   patch:
#    metadata:
#      annotations:
#        example.com/test: "true"
#      labels:
#        example.com/prod_level: "{{ prod_level }}"
# - ...
# Patches are applied in the order they are specified.

# Set to true to remove the role binding to anonymous users created by kubeadm
remove_anonymous_access: false
```

## Step 10: change variable file: group_vars/k8s_cluster/k8s-net-calico.yml

## Step 11: run ansible playbook

```
ansible-playbook -i inventory/cluster-vi/inventory.ini cluster.yml --tags=download
ansible-playbook -i inventory/cluster-vi/inventory.ini cluster.yml --become --become-user=root --user=kubespray
```

## Step 12: check the cluster and smoke test

```
kubectl get nodes
kubectl get pods -n kube-system
kubectl top nodes

kubectl create deployment nginx --image=nginx

```

