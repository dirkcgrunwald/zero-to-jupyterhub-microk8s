# Basic install of Zero-to-Jupyter using k3s

## Install k3s

Following the directions at [k3s.io](k3s.io), which are:
```
curl -sfL https://get.k3s.io | sh -
# Check for Ready node, takes maybe 30 seconds
k3s kubectl get node
```
This assumes you have `sudo` permissions.

## Add access to your k3s cluster

K3s has a configuration file at `/etc/rancher/k3s/k3s.yaml` that contains secrets you need to manage k3s. The file is only readable by `root`. There are [several ways to manages access](https://rancher.com/docs/k3s/latest/en/cluster-access/), but the easiest is to copy that data to your `~/.kube/config` file. This is not very secure.

```
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/kubeconfig
sudo chown $USER $HOME/kubeconfig
export KUBECONFIG=$HOME/kubeconfig
```

You should now be to run
```
kubectl get nodes
```
and see information about your (single) node.

## Install helm

[Helm](helm.sh) is a package manager for Kubernetes. You should [install helm](https://helm.sh/docs/intro/install/) using the appropriate method.

If you're running Ubuntu you can do:
```
sudo snap install helm --classic
```
and in general, you can use
```
https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

## Add the JupyterHub Helm chart

Helm uses "charts" to install software. Grab the latest charts:
```
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
```

## Install JupyterHub

Make certain you're in the "basic" directory since some file paths assume that.

The quick-start steps are:
```
helm install jhub jupyterhub/jupyterhub --version=0.9.0 --values=z2jh-config.yaml
```
This will take a few seconds and you'll eventually see a message thanking you for installing jupyterhub.

You can check that things are running using, e.g.:
```
user@host:~/zero-to-jupyterhub-k3s/basic$ kubectl get po
NAME           TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kubernetes     ClusterIP   10.43.0.1      <none>        443/TCP    4h31m
proxy-api      ClusterIP   10.43.70.164   <none>        8001/TCP   6s
proxy-public   ClusterIP   10.43.49.255   <none>        80/TCP     6s
hub            ClusterIP   10.43.77.3     <none>        8081/TCP   6s
```

## Install the ingress

Now, run
```
kubectl apply -f jupyter-ingress.yaml
```
You should now be able to go to you host and login using dummy credentials (e.g. user `foo` with password `bar`). When you log in, the default Jupyter container will be downloaded and you'll start in the JupyterLab interface.

You now have a basic working Z2JH setup.

## Details about config.yaml and jupyter-ingress.yaml

Z2JH comes with configuration options to automatically create a security certificate using `letsencrypt` and uses a "load balancer" to connect to an internal "ingress" that connects to the the internal jupyterhub proxy (`proxy-public` in the above). In environments like Google Kubernetes Enginer (GKE) this will connect ports 80 and 443 to `proxy-public` and the internally configure "ingress" will automatically request your security certificates.

Unfortunatly, the basic install of `k3s` directly uses `traefik` as the ingress and expects to resolve all TLS/HTTPS connections there, meaning Z2JH never gets the pure HTTPS connections. In [config.yaml](config.yaml), we've disabled Z2JH from using HTTPS. If you want HTTPS, see the next setup guide.

Because our [config.yaml](config.yaml) directs Z2JH to use an IP address in the cluster, we have to tell the public network address how to connect to the internal service. This is done by file [jupyter-ingress.yaml](jupyter-ingress.yaml).

Also, [config.yaml](config.yaml) specifies a "secret" that provides security within your Z2JH cluster. We've used a default value but you [should follow the directions to create something more secure](https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html).

## Removing things and cleaning up

In our simple setup, we didn't use "namespaces" because it's slighly more complicated, but it means we need to take an additional step cleaning things up (we need to remove the storage). Alternatively, you can just remove the entire `k3s` system which will clean everything up.

You can [read more about cleanup using namespaces](https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/turn-off.html) to decide what you'll do going forward.

### Remove jupyterhub

Use helm to delete the Z2JH stuff we added:
```
helm delete jhub
```
where `jhub` is the name we assigned to this specific cluster in the `helm create` command. You will also need to delete the `ingress`:
```
kubectl delete ingress jupyter-ingress
```

### Cleaning up storage

With the default setup, each login creates a `pvc` (physical volume claim) to a `pv` (physical volume) that hold the users local files and a single `pv` that holds the user authentication database, `hub-db-dir`.

For example, if user `foo` and `second` logged in, you may see:
```
user@host:~/zero-to-jupyterhub-k3s/basic$ kubectl get pvc
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
claim-foo      Bound    pvc-394edbe6-7ba3-4981-9331-7617e4d3fd77   10Gi       RWO            local-path     15m
hub-db-dir     Bound    pvc-5ccd6714-16c2-4ce0-86b4-d02d71886054   1Gi        RWO            local-path     13m
claim-second   Bound    pvc-60491f32-68bc-4786-b87d-75f67c312285   10Gi       RWO            local-path     8s
```
Removing JupyterHub using `helm` will remove the database PV but not the user data (this is intentional). You can remove them using e.g.
```
kubectl delete pvc claim-foo
```
This may take some time to complete (a minute or more) and can be forked to the background.

### Removing k3s

If you want to put everything back like you found it, you can remove k3s:
```
sudo /usr/local/bin/k3s-uninstall.sh 
```