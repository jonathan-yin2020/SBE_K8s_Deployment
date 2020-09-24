#!/bin/bash

source tmp/VAR.txt

export PATH=$PATH:"${PWD%/*}"

aws ec2 terminate-instances --profile $AWS_PROFILE --endpoint http://$SNOW_IP:8008 --instance-id $(sed '1q;d' tmp/instance.txt)
aws ec2 terminate-instances --profile $AWS_PROFILE --endpoint http://$SNOW_IP:8008 --instance-id $(sed '2q;d' tmp/instance.txt)
aws ec2 terminate-instances --profile $AWS_PROFILE --endpoint http://$SNOW_IP:8008 --instance-id $(sed '3q;d' tmp/instance.txt)

snowballEdge describe-virtual-network-interfaces --profile $SNOW_PROFILE | jq -c '.VirtualNetworkInterfaces[] | .VirtualNetworkInterfaceArn' | sed 's/.//;s/.$//' > tmp/instance.txt
echo "Wait for instances be terminated"
sleep 60 

snowballEdge delete-virtual-network-interface --profile $SNOW_PROFILE --virtual-network-interface-arn $(sed '1q;d' tmp/instance.txt)
snowballEdge delete-virtual-network-interface --profile $SNOW_PROFILE --virtual-network-interface-arn $(sed '2q;d' tmp/instance.txt)
snowballEdge delete-virtual-network-interface --profile $SNOW_PROFILE --virtual-network-interface-arn $(sed '3q;d' tmp/instance.txt)
echo "All Clean, Thank you for trying!!"
rm -rf tmp/
