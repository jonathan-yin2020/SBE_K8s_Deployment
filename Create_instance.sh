#!/usr/bin/env bash

# Make snowballEdge can be excute anywhere
export PATH=$PATH:"${PWD%/*}"

# Create a tmp directory 
mkdir -p tmp/

# Set the SSH Cert
CERT="${PWD%/*}"/jan20-snowlab.pem

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
      --instance-type $SBE \
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

# Set ec2 instance type
read -p "Please enter the instance type: "
echo "SBE=$REPLY" >> tmp/VAR.txt

# Set SBE IP Address
read -p "Please enter snowball IP: "
echo "SNOW_IP=$REPLY" >> tmp/VAR.txt

# Set Snowball and AWS Profile
read -p "Please enter the snowball profile name: "
echo "SNOW_PROFILE=$REPLY" >> tmp/VAR.txt

read -p "Please enter the AWSCLI profile name: "
echo "AWS_PROFILE=$REPLY" >> tmp/VAR.txt

# Create cluster instances
read -p "Enter Master Node IP: "
echo "MASTER_IP=$REPLY" >> tmp/VAR.txt

read -p "Enter 1st Worker Node IP: "
echo "WORKER_IP1=$REPLY" >> tmp/VAR.txt

read -p "Enter 2nd Worker Node IP: "
echo "WORKER_IP2=$REPLY" >> tmp/VAR.txt

#echo "Enter NFS IP:"
#read NFS_IP
source tmp/VAR.txt

# RJ45 VNIC interface id
export PHYS_IF=`snowballEdge describe-device --profile $SNOW_PROFILE | jq -c '.PhysicalNetworkInterfaces[] | select(.PhysicalConnectorType == "RJ45" )| .PhysicalNetworkInterfaceId'`

# CentOS Image Id for this snowball
export IMAGE=`aws ec2 describe-images --profile $AWS_PROFILE --endpoint http://$SNOW_IP:8008 | jq -c '.Images[] | select(.Name == "CentOS 7 20GiB - 8 Jan 2020") | .ImageId' | sed 's/.//;s/.$//'`

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
aws ec2 wait instance-running --profile $AWS_PROFILE --endpoint http://$SNOW_IP:8008 \
--instance-ids $(sed '1q;d' tmp/instance.txt) $(sed '2q;d' tmp/instance.txt) $(sed '3q;d' tmp/instance.txt)

# Assign public IP for all nodes
ASSO_VNIC $MASTER_IP $(sed '1q;d' tmp/instance.txt) && ASSO_VNIC $WORKER_IP1 $(sed '2q;d' tmp/instance.txt) && ASSO_VNIC $WORKER_IP2 $(sed '3q;d' tmp/instance.txt) 
#ASSO_VNIC $NFS_IP $(sed '4q;d' instance.txt)
sleep 10

# Quick reboot to update the hostname
ssh -i $CERT centos@$MASTER_IP -o StrictHostKeyChecking=no "sudo reboot" &
ssh -i $CERT centos@$WORKER_IP1 -o StrictHostKeyChecking=no "sudo reboot" &
ssh -i $CERT centos@$WORKER_IP2 -o StrictHostKeyChecking=no "sudo reboot" &
sleep 30
echo -e "Instances are now public accessable."
