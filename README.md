# SBE_K8s_Deployment

This is to demo 3 nodes Kubernetes cluster deployment on single Snowball Edge device. There are a local Docker Registry and Open GEE with Nginx running in this demo.\
Go to /GEEDocker for code to build the latest Open GEE into Docker images and /K8s_private_registry for code to start and stop local registry.

![flow][flow]
# Prerequisites before create the infrastructure

## Clone this repo and copy the require .pem cert for your AMI into the snowball-client-linux-1.0.1-335/bin directory

## Take note of the instance type you want to create. For example: sbe1.xlarge for storage optimized and sbe-c.xlarge for compute optimized

## Create Snowball Edge and AWS Cli profiles

    snowballEdge configure --profile && aws configure --profile

If you not sure how to do it, check out the following links\
https://docs.aws.amazon.com/snowball/latest/developer-guide/using-client-commands.html#client-configuration\
https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

## This NFS setup with 4 shared folder. Some shared folders might require extra data copy prior to mount to the container, this is depended on your application requirements.
## Show different ownership and permission of the shared folders
![nfs][nfs]

## /etc/exports
![nfs1][nfs1]

Check out the following link for how to setup NFS\
https://www.tecmint.com/how-to-setup-nfs-server-in-linux/

# Deploy infrastructure

## Create 3 instances with public IP assigned

    ./SBE_K8s_Deployment/Create_instance.sh

## Once verified SSH accessibility to the instances, run the next script to finish the rest of the depolyment 

    ./SBE_K8s_Deployment/Create_K8s.sh

[flow]: https://user-images.githubusercontent.com/64214379/93840135-8a866900-fc4c-11ea-81c5-2d14f8c0d06b.png
[nfs]: https://user-images.githubusercontent.com/64214379/94060523-54a6c900-fda1-11ea-9268-0ccbeabbaefb.png
[nfs1]: https://user-images.githubusercontent.com/64214379/94060533-58d2e680-fda1-11ea-9a34-836cc1273797.png
