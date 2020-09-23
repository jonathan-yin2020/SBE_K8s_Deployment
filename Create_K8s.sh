#!/bin/bash

source tmp/VAR.txt

# Set the SSH Cert
CERT="${PWD%/*}"/jan20-snowlab.pem

echo "Enter Private Registry Username:"
read USERN

echo "Enter Private Registry Password:"
read USERP

echo -e " *****************************************************\n \
Wait for the cluster being setup, come back in 5 mins\n \
*****************************************************"
# Node setup
ssh -i $CERT centos@$MASTER_IP "sudo bash -s" < K8s_install/master1.sh > tmp/node1.log 2>&1 &
sleep 10
ssh -i $CERT centos@$WORKER_IP1 "sudo bash -s" < K8s_install/worker-node.sh > tmp/node2.log 2>&1 &
sleep 10
ssh -i $CERT centos@$WORKER_IP2 "sudo bash -s" < K8s_install/worker-node.sh > tmp/node3.log 2>&1 &
sleep 270

echo "Master Node is now ready for other nodes to join!"

ssh -i $CERT centos@$MASTER_IP "bash -s" < K8s_install/master2.sh > tmp/node4.log 2>&1 &
sleep 10

JOIN=`tail -2 tmp/node1.log | sed 's|[\,]||' | awk '$1=$1'` 
ssh -i $CERT centos@$WORKER_IP1 sudo $JOIN >> tmp/node4.log 2>&1 &
ssh -i $CERT centos@$WORKER_IP2 sudo $JOIN >> tmp/node4.log 2>&1 &
sleep 60

ssh -i $CERT centos@$MASTER_IP "kubectl get node"
echo -e "Nodes setup are successful completed\n"
sleep 10

echo -e "Download file from Github\n"
ssh -i $CERT centos@$MASTER_IP "git clone https://github.com/jonathan-yin2020/SBE_K8s_Deployment.git"
sleep 20

echo -e "Starting Private Registry and GEE"
ssh -i $CERT centos@$MASTER_IP "cd SBE_K8s_Deployment/K8s_GEE && kubectl apply -f pv-nfs.yml"
sleep 10
ssh -i $CERT centos@$MASTER_IP "cd SBE_K8s_Deployment/K8s_GEE && kubectl apply -f pvc-nfs.yml"
sleep 10

echo -e "$USERN\n$USERP" | ssh -i $CERT centos@$MASTER_IP "cd SBE_K8s_Deployment/K8s_private_registry && ./start-docker-private-registry"
sleep 5
ssh -i $CERT centos@$MASTER_IP "cd SBE_K8s_Deployment/K8s_GEE && kubectl apply -f gee-nginx.yaml"