## 1- update all k8s nodes

```
apt update
apt upgrade -y
```

## 2- reboot server

## 3- purge old files

```
apt autoremove -y
```

## 4- check chrony configuration

## 5- check dns configuration in netplan

## 6- create passwordless sudoer user on all k8s nodes

```
useradd -m kubespray
passwd kubespray
usermod -s /bin/bash kubespray
echo 'kubespray ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/kubespray
```


## on the operation server ##

## 1- copy operation server pub key to all k8s nodes

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

## 2- change directory

```
cd /app/workspace/cloud-native/kubernetes/cluster-vi/kubespray/kubespray-2.28.0
```

## 3- create venve

```
python3 -m venv vi-kubespray-venv
source vi-kubespray-venv/bin/activate
```

## 4- install kubespray requirements

```
pip3 install -U -r requirements.txt
```

## 5- change node ips in inventory/vi-cluster/inventory.ini file


## 6- deploy cluster

```
ansible-playbook -i inventory/vi-cluster/inventory.ini cluster.yml --become --become-user=root --user=kubespray
```


