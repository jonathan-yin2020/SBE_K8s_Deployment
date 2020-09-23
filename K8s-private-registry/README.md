# K8s-private-registry
This private registry is password protected. The password data and the images in the repo is persisted in NFS through the use of PV and PVC. The images are mounted under /var/lib/registry and the user data is mounted at /auth.

![flow][flow]
# Start/Stop private registry in  K8s cluster

## start private registry<a id="sec-1-1" name="sec-1-1"></a>

    ./start-docker-private-registry

## stop private registry

    ./stop-docker-private-registry

# Registry access<a id="sec-2" name="sec-2"></a>

Use the following address/port to push, pull images

    127.0.0.1:5000

## Test the registry

Check if the registry catalog can be accessed 

     curl  127.0.0.1:5000/v2/_catalog 

Test if it's possible to push image to the local repo

     docker pull busybox && docker tag busybox 127.0.0.1:5000/busybox && docker push 127.0.0.1:5000/busybox

Check the image with the tags

     curl  127.0.0.1:5000/v2/busybox/tags/list

# Upload and download images for private registry from the NFS directory

## create a /backup directory

     mkdir /backup

## compress and download all images from share directory 

     tar -cvf /backup/registry-data.tar .

## decompress and upload the tar file to share directory

     tar -xvf /backup/registry-data.tar .

[flow]: https://user-images.githubusercontent.com/64214379/93840135-8a866900-fc4c-11ea-81c5-2d14f8c0d06b.png
