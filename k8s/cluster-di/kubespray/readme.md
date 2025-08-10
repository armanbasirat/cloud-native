# create passwordless sudoer user on all k8s nodes

# adduser kubespray

useradd -m kubespray
passwd kubespray
usermod -s /bin/bash kubespray


# passwordless sudoer kubespray user

echo 'kubespray ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/kubespray

------------------------------------------------------------------------------

# on operation server

# create ssh-keygen

ssh-keygen


# copy pub key to k8s nodes

ssh-copy-id kubespray@cp1
ssh-copy-id kubespray@cp2
ssh-copy-id kubespray@cp3
ssh-copy-id kubespray@cp4
ssh-copy-id kubespray@cp5

ssh-copy-id kubespray@wrkr1
ssh-copy-id kubespray@wrkr2
ssh-copy-id kubespray@wrkr3
ssh-copy-id kubespray@wrkr4


# install pip

sudo apt install -y python3-pip
sudo apt install -y python3.10-venv

git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
python3 -m venv da-kubespray-venv
source da-kubespray-venv/bin/activate
pip3 install -U -r requirements.txt
cp -rfp inventory/sample inventory/pa-cluster1

# change nodes in inventory/da-cluster1/inventory.ini


ansible-playbook -i inventory/da-cluster1/inventory.ini cluster.yml --become --become-user=root --user=kubespray



