#!/bin/bash

# Disable SELinux.
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

# Enable the br_netfilter module for cluster communication.
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

# Disable swap to prevent memory allocation issues.
swapoff -a

# Install the Docker prerequisites.
yum install -y yum-utils device-mapper-persistent-data lvm2 git

# Add the Docker repo and install Docker.
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce

# Configure the Docker Cgroup Driver to systemd, enable and start Docker
sed -i '/^ExecStart/ s/$/ --exec-opt native.cgroupdriver=systemd/' /usr/lib/systemd/system/docker.service 
systemctl daemon-reload
systemctl enable docker --now 

# Add the Kubernetes repo.
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
      https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Install Kubernetes.
yum install -y kubelet kubeadm kubectl

# Enable Kubernetes. The kubelet service will not start until you run kubeadm init.
systemctl enable kubelet

echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
# Initialize the cluster using the IP range for Flannel.
kubeadm init --pod-network-cidr=10.244.0.0/16