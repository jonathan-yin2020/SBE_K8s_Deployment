#!/bin/bash

source tmp/VAR.txt

export PATH=$PATH:"${PWD%/*}"

while read INSTANCE; do
    aws ec2 terminate-instances --profile $AWS_PROFILE --endpoint http://$SNOW_IP:8008 --instance-id $INSTANCE
done < tmp/instance.txt

echo "Wait for instances be terminated"

snowballEdge describe-virtual-network-interfaces --profile $SNOW_PROFILE | jq -c '.VirtualNetworkInterfaces[] | .VirtualNetworkInterfaceArn' | sed 's/.//;s/.$//' > tmp/network.txt
tail -3 tmp/network.txt
sleep 60 

while read INTERFACE; do
    snowballEdge delete-virtual-network-interface --profile $SNOW_PROFILE --virtual-network-interface-arn $INTERFACE
done < tmp/network.txt

echo "All Clean, Thank you for trying!!"

rm -rf tmp/
