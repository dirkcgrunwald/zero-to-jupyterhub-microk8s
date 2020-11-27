# Basic install of Zero-to-Jupyter using k3s

## Install microk8s

Following the directions at [microk8s.io](https://microk8s.io/), which are:
```
sudo snap install microk8s --classic
```

You need to [add additional modules](https://microk8s.io/docs/addons):
```
microk8s enable dashboard dns storage cilium metallb helm3
```
When you add the `metallb` module, you will be asked for a range of IP addresses that the load balancer can use when services request a `LoadBalancer` service type. If your host IP address is `123.456.789.123` you should enter `123.456.789.123-123.456.789.123` because it wants a range of values.

## Add access to your k3s cluster
Microk8s uses the `microk8s` command as a prefix, similar to minikube.
When you first run `microk8s kubectl get po` you'll be prompted to add yourself to the microk8s group and log back in. That provides the permissions to access the needed credentials.

You should now be to run
```
microk8s kubectl get nodes
```
and see information about your (single) node.

## Install helm

[Helm](helm.sh) is a package manager for Kubernetes. You should [install helm](https://helm.sh/docs/intro/install/) using the appropriate method.

Microk8s comes with it's own version of Helm that is executed by prefixing with `microk8s` as in `microk8s helm`.

You may want to install a standard release as well but it won't pick up the fact that you need to prefix your `kubectl` commands using `microk8s kuebctl`. If you're running Ubuntu you can do:
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
microk8s helm3 repo add jupyterhub https://jupyterhub.github.io/helm-chart/
microk8s helm3 repo update
```

## Install JupyterHub

Make certain you're in the "basic" directory since some file paths assume that.

The quick-start steps are:
```
microk8s helm3 install jhub jupyterhub/jupyterhub --version=0.10.5 --values=z2jh-config.yaml
```
This will take a few seconds and you'll eventually see a message thanking you for installing jupyterhub.

You can check that things are running using, e.g.:
```
user@host:~/zero-to-jupyterhub-k3s/basic$ microk8s kubectl get po
runwald@beast:~/zero-to-jupyterhub-microk8s/basic$ microk8s kubectl get po
NAME                              READY   STATUS    RESTARTS   AGE
continuous-image-puller-444k8     1/1     Running   0          4m48s
user-scheduler-7f7b8c65bc-wgwj8   1/1     Running   0          4m48s
proxy-c845cb89b-cbwhl             1/1     Running   0          4m48s
user-scheduler-7f7b8c65bc-rq96m   1/1     Running   0          4m48s
hub-86cc79d976-89vwm              1/1     Running   0          4m48s
jupyter-foo                       1/1     Running   0          2m34s
```

## Check for connectivity

Because you've installed Metallb, you don't need to specify an ingress -- the Z2JH distribution will automatically install the `traefik` ingress which will allocate a `LoadBalancer` port. You can determine the the `LoadBalancer` has been allocated by looking at the services -- you should see the IP address you entered when you enabled the `metallb` extension to `microk8s`.
```
grunwald@beast:~/zero-to-jupyterhub-microk8s/basic$ microk8s kubectl get svc
NAME           TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)        AGE
kubernetes     ClusterIP      10.152.183.1     <none>          443/TCP        4h58m
proxy-api      ClusterIP      10.152.183.111   <none>          8001/TCP       5m25s
hub            ClusterIP      10.152.183.226   <none>          8081/TCP       5m25s
proxy-public   LoadBalancer   10.152.183.5     192.12.242.33   80:30800/TCP   5m25s
```
You should now be able to go to you host and login using dummy credentials (e.g. user `foo` with password `bar`). When you log in, the default Jupyter container will be downloaded and you'll start in the JupyterLab interface.

You now have a basic working Z2JH setup.

## Details about config.yaml 

The [config.yaml](config.yaml) file specifies a "secret" that provides security within your Z2JH cluster. We've used a default value but you [should follow the directions to create something more secure](https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html).

## Removing things and cleaning up

In our simple setup, we didn't use "namespaces" because it's slighly more complicated, but it means we need to take an additional step cleaning things up (we need to remove the storage). Alternatively, you can just remove the entire `microk8s` system which will clean everything up.

You can [read more about cleanup using namespaces](https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/turn-off.html) to decide what you'll do going forward.

### Remove jupyterhub

Use helm to delete the Z2JH stuff we added:
```
microk8s helm3 delete jhub
```
where `jhub` is the name we assigned to this specific cluster in the `helm create` command. 

### Cleaning up storage

With the default setup, each login creates a `pvc` (physical volume claim) to a `pv` (physical volume) that hold the users local files and a single `pv` that holds the user authentication database, `hub-db-dir`.

For example, if user `foo` and `second` logged in, you may see:
```
user@host:~/zero-to-jupyterhub-k3s/basic$ microk8s kubectl get pvc
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
claim-foo      Bound    pvc-394edbe6-7ba3-4981-9331-7617e4d3fd77   10Gi       RWO            local-path     15m
hub-db-dir     Bound    pvc-5ccd6714-16c2-4ce0-86b4-d02d71886054   1Gi        RWO            local-path     13m
claim-second   Bound    pvc-60491f32-68bc-4786-b87d-75f67c312285   10Gi       RWO            local-path     8s
```
Removing JupyterHub using `helm` will remove the database PV but not the user data (this is intentional). You can remove them using e.g.
```
microk8s kubectl delete pvc claim-foo
```
This may take some time to complete (a minute or more) and can be forked to the background.

### Removing microk8s

If you want to put everything back like you found it, you can remove k3s:
```
snap remove microk8s
```
