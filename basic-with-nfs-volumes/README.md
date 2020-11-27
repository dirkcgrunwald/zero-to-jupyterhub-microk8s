# Adding NFS to the basic Z2JH on k3s

By default, Z2JH uses the default PV's (physical volumes) provided by the underlying kubernetes system. These volumes usually allocate a fixed amount of space, take a while to allocate and can't be shared between users. It's sometimes desirable to use NFS for PV's because users files will all come from a fixed pool of storage, they're quicker to create and you can share volumes between users.

This guide walks you though installing an `nfs-server-provisioner` that then lets other Kubernetes pods ask for volumes of type "nfs".

## Install the NFS server provisioner

Deploy an NFS volume provisioner [using Helm](https://hub.helm.sh/charts/stable/nfs-server-provisioner/1.1.1) with the provides [NFS configuration file](nfs-config.yaml).

```
microk8s helm3 repo add stable https://kubernetes-charts.storage.googleapis.com 
microk8s helm3 repo update
microk8s helm3  install jhub-nfs stable/nfs-server-provisioner --version=1.1.2 --namespace default --values=nfs-config.yaml
```
The supplied configuration will try to create a 20Gi volume from which individual user volumes are carved.

## Configure Z2JH to use NFS volumes

The file [z2jh-config-with-nfs.yaml](z2jh-config-with-nfs.yaml) changes the storage allocation information to give each user 0.5Gi of storage from the NFS server. Update the Jupyterhub configurating using that config file:
```
microk8s helm3 upgrade jhub jupyterhub/jupyterhub --version=0.10.3 --values=z2jh-config-with-nfs.yaml
```
Now, try to log into your Jupyterhub again using a new user (_e.g._ user 'try' with password 'again'). It should start up as normal, but when you look at the PVC you'll see it's an NFS volume rather than a built-in one.
```
user@host:~/zero-to-jupyterhub-k3s/basic-with-nfs-volumes$ microk8s kubectl get pvc claim-try
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
claim-try   Bound    pvc-88ddd225-2fec-4354-b9ce-c8c7a62d6f10   512Mi      RWO            nfs            40s
```
Although the volume appears to be limited in size, there don't appear to be actual storage quotas, meaning one user can suck up all the storage.

## Using shared volumes

It's also possible to create additional volumes and then share them between users. The file [z2jh-config-with-shared-nfs.yaml](z2jh-config-with-shared-nfs.yaml) changes the storage allocation information to mount a single PVC called `jupyterhub-shared-volume` at location `$HOME/shared/example`. The shared volume needs to be created before you try to mount it or users will hang waiting for the volume to be available.

This configuration isn't that useful but can serve as the basis for a more robust setup.

First, create the volume:
```
microk8s kubectl apply -f make-shared-nfs-volume.yaml
```
and then upgrade JupyterHub to use the shared volume:
```
microk8s helm3 upgrade jhub jupyterhub/jupyterhub --version=0.10.5 --values=z2jh-config-with-shared-nfs.yaml
```

Changes to volumes, such as adding a new shared volume, will only take affect when the "pod" for a given user is created. Because of that, all of out `z2jh-config.yaml` files contain this stanza:
```
hub:
  shutdownOnLogout: True 
```
which instructs JupyterHub to terminate the "pod" for the user when they logout.

If you're not seeing the shared volume mounting, try logging in with a new user name to force a new pod to be created, or explicitly "logout" of an existing session, or force the deletion of a pod using, _e.g._:
```
kubectl delete pod jupyter-try
```
for user `try`.