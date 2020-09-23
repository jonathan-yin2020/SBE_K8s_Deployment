#!/bin/bash

aws ec2 terminate-instances --profile snow666 --endpoint http://10.42.0.156:8008 --instance-id $(sed '1q;d' tmp/instance.txt)
aws ec2 terminate-instances --profile snow666 --endpoint http://10.42.0.156:8008 --instance-id $(sed '2q;d' tmp/instance.txt)
aws ec2 terminate-instances --profile snow666 --endpoint http://10.42.0.156:8008 --instance-id $(sed '3q;d' tmp/instance.txt)

snowballEdge describe-virtual-network-interfaces --profile snow666 | jq -c '.VirtualNetworkInterfaces[] | .VirtualNetworkInterfaceArn' | sed 's/.//;s/.$//' > tmp/instance.txt
sleep 30 

snowballEdge delete-virtual-network-interface --profile snow666 --virtual-network-interface-arn $(sed '4q;d' tmp/instance.txt)
snowballEdge delete-virtual-network-interface --profile snow666 --virtual-network-interface-arn $(sed '5q;d' tmp/instance.txt)
snowballEdge delete-virtual-network-interface --profile snow666 --virtual-network-interface-arn $(sed '6q;d' tmp/instance.txt)
