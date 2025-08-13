# Deploy a Production Ready Kubernetes Cluster with Kubespray


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


## 1- create ssh-keygen

```
ssh-keygen
```

### install pip and venv

```
sudo apt install -y python3-pip && python3.10-venv
```

### copy operation server pub key to all k8s nodes

```
ssh-copy-id kubespray@<cp1>
ssh-copy-id kubespray@<cp2>
ssh-copy-id kubespray@<cp3>
ssh-copy-id kubespray@<cp4>
ssh-copy-id kubespray@<cp5>

ssh-copy-id kubespray@<wrkr1>
ssh-copy-id kubespray@<wrkr2>
ssh-copy-id kubespray@<wrkr3>
ssh-copy-id kubespray@<wrkr4>
```


## Step 02: get kubespray with specific tag:

#### curl <github-repository>/kubernetes-sigs/kubespray/archive/refs/tags/v2.28.0.zip -o kubespray-2.28.0.zip

```
mkdir -p /root/workspace/cluster-vi
cd /root/workspace/cluster-vi
curl http://192.168.106.12:8081/repository/github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.28.0.zip -o kubespray-2.28.0.zip
unzip kubespray-2.28.0.zip
cd kubespray-2.28.0
```

## Step 03: installing ansible and change inventory file

```
python3 -m venv vi-kubespray-venv
source vi-kubespray-venv/bin/activate
```

#### index-url = <pypi-repository>/simple
#### trusted-host = <nexus-ip>

```
cat <<EOF > vi-kubespray-venv/pip.conf
[global]
index-url = http://192.168.106.12:8081/repository/pypi.org/simple
trusted-host = 192.168.106.12
EOF
```

```
pip3 install -U -r requirements.txt
```

```
cp -rfp inventory/sample inventory/cluster-vi
```

```
[kube_control_plane]
node1 ansible_host=<cp1> etcd_member_name=etcd1
node2 ansible_host=<cp2> etcd_member_name=etcd2
node3 ansible_host=<cp3> etcd_member_name=etcd3
node4 ansible_host=<cp4> etcd_member_name=etcd4
node5 ansible_host=<cp5> etcd_member_name=etcd5

[etcd:children]
kube_control_plane

[kube_node]
node6 ansible_host=<wr1>
```

## Step 04: change variable file: group_vars/all/all.yml

## Step 05: change variable file: group_vars/all/containerd.yml


#### containerd_registries_mirrors:
####  - prefix: docker.io
####    mirrors:
####      - host: <docker-repository>
####        capabilities: ["pull", "resolve"]
####  - prefix: registry.k8s.io
####    mirrors:
####      - host: <k8s-repository>
####        capabilities: ["pull", "resolve"]
####  - prefix: quay.io
####    mirrors:
####      - host: <quay-repository>
####        capabilities: ["pull", "resolve"]



```
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
```

## Step 06: change variable file: group_vars/all/etcd.yml

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

## Step 09: change variable file: group_vars/k8s_cluster/k8s-cluster.yml

## Step 10: change variable file: group_vars/k8s_cluster/k8s-net-calico.yml

## Step 11: run ansible playbook

```
ansible-playbook -i inventory/cluster-vi/inventory.ini cluster.yml --become --become-user=root --user=kubespray
```

## Step 12: access and check the kubernetes cluster and Smoke test

