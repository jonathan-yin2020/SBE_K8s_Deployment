#!/usr/bin/env bash

# Make snowballEdge can be excute anywhere
export PATH=$PATH:$PWD

# Create a tmp directory 
mkdir -p tmp/

# Set the SSH Cert
CERT="jan20-snowlab.pem"

function CREATE_NETWORK {
    snowballEdge create-virtual-network-interface \
      --physical-network-interface-id $PHYS_IF \
      --ip-address-assignment STATIC \
      --static-ip-address-configuration IpAddress=$1,Netmask=255.255.255.0 \
      --profile $SNOW_PROFILE \
      --endpoint https://$SNOW_IP
}

function CREATE_INSTANCE {
    aws ec2 run-instances \
      --count 3 \
      --image-id $IMAGE \
      --instance-type sbe-c.2xlarge \
      --endpoint http://$SNOW_IP:8008 \
      --profile $AWS_PROFILE
}

function CREATE_NFS {
    aws ec2 run-instances \
      --count 1 \
      --image-id $IMAGE \
      --instance-type sbe-c.large \
      --block-device-mappings "DeviceName=/dev/sdb,Ebs={DeleteOnTermination=true,VolumeSize=500,VolumeType=sbg1}" \
      --endpoint http://$SNOW_IP:8008 \
      --profile $AWS_PROFILE
}
function ASSO_VNIC {
    aws ec2 associate-address \
      --endpoint http://$SNOW_IP:8008 \
      --profile $AWS_PROFILE \
      --public-ip $1 \
      --instance-id $2
}

# Set SBE IP Address
echo "Please enter snowball IP:"
read SNOW_IP

# Set Snowball and AWS Profile
echo "Please enter the snowball profile name:"
read SNOW_PROFILE

echo "Please enter the AWSCLI profile name:"
read AWS_PROFILE


# RJ45 VNIC interface id
export PHYS_IF=`snowballEdge describe-device --profile $SNOW_PROFILE | jq -c '.PhysicalNetworkInterfaces[] | select(.PhysicalConnectorType == "RJ45" )| .PhysicalNetworkInterfaceId'`

# CentOS Image Id for this snowball
export IMAGE=`aws ec2 describe-images --profile $AWS_PROFILE --endpoint http://$SNOW_IP:8008 | jq -c '.Images[] | select(.Name == "CentOS 7 20GiB - 8 Jan 2020") | .ImageId' | sed 's/.//;s/.$//'`

# Create cluster instances
echo "Enter Master Node IP:"
read MASTER_IP

echo "Enter 1st Worker Node IP:"
read WORKER_IP1

echo "Enter 2nd Worker Node IP:"
read WORKER_IP2

#echo "Enter NFS IP:"
#read NFS_IP

# Create Public IP
CREATE_NETWORK $MASTER_IP && CREATE_NETWORK $WORKER_IP1 && CREATE_NETWORK $WORKER_IP2
#CREATE_NETWORK $NFS_IP
sleep 5

# Create Instance
CREATE_INSTANCE | jq -c '.Instances[] | .InstanceId' | sed 's/.//;s/.$//' > tmp/instance.txt 
#CREATE_NFS | jq -c '.Instances[] | .InstanceId' | sed 's/.//;s/.$//' >> tmp/instance.txt
echo -e " *************************************************\n \
Instances are being created, comeback in 2 mins!!\n \
*************************************************"
sleep 120

# Assign public IP for all nodes
ASSO_VNIC $MASTER_IP $(sed '1q;d' tmp/instance.txt) && ASSO_VNIC $WORKER_IP1 $(sed '2q;d' tmp/instance.txt) && ASSO_VNIC $WORKER_IP2 $(sed '3q;d' tmp/instance.txt) 
#ASSO_VNIC $NFS_IP $(sed '4q;d' instance.txt)
sleep 30

# Quick reboot to update the hostname
ssh -i $CERT centos@$MASTER_IP -o StrictHostKeyChecking=no "sudo reboot" &
ssh -i $CERT centos@$WORKER_IP1 -o StrictHostKeyChecking=no "sudo reboot" &
ssh -i $CERT centos@$WORKER_IP2 -o StrictHostKeyChecking=no "sudo reboot" &
echo -e "Instances are now public accessable.\nQuick reboot for hostname to update."
sleep 40


echo -e " ********************************\n \
Wait for the cluster being setup\n \
********************************"
# Node setup
ssh -i $CERT centos@$MASTER_IP "sudo bash -s" < master1.sh > tmp/node1.log 2>&1 &
sleep 10
ssh -i $CERT centos@$WORKER_IP1 "sudo bash -s" < worker-node.sh > tmp/node2.log 2>&1 &
sleep 10
ssh -i $CERT centos@$WORKER_IP2 "sudo bash -s" < worker-node.sh > tmp/node3.log 2>&1 &
sleep 120

ssh -i $CERT centos@$MASTER_IP "bash -s" < master2.sh > tmp/node4.log 2>&1 &
sleep 10

JOIN=`tail -2 tmp/node1.log | sed 's|[\,]||' | awk '$1=$1'` 
ssh -i $CERT centos@$WORKER_IP1 sudo $JOIN 2>&1 &
ssh -i $CERT centos@$WORKER_IP2 sudo $JOIN 2>&1 &
sleep 10

ssh -i $CERT centos@$MASTER_IP kubectl get node
echo "Install completed successfully"