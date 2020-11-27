# Making Z2JH fancy

The following configuration builds on the Z2JH using NFS shared files.

This configuration extends JupyterHub to:
* Allow shared mounts for specified users
* Fancy graphics layout

## Shared Mounts

The file [shared-mounts.json](shared-mounts.json) contains a JSON specification of volumes that should be mounted under `~/shared` for the specified users. For example:
```
{
    "example" : [ "foo", "bar" ],
    "another" : [ "bar", "try"]
}
```
would provide `~/shared/example` for users `foo` and `bar`, and `~/shared/another` for users `bar` and `try`.

The mounts are checked whenever a pod is created (i.e. at login). The [z2jh-config-fancy.yaml](z2jh-config-fancy.yaml) configuration file contains code that opens `shared-mounts.json` in the "hub". If the file doesn't exist, it doesn't do anything.

In order to have that file on the "hub", you need to copy it there. A script is provided:
```
sh COPY-TO-HUB.sh shared-mounts.json shared-mounts.json
```
The volumes need to exist before they are referenced or the users will "hang" waiting for them to exist. Create the sample volumes using
```
microk8s kubectl apply -f make-shared-nfs-volumes.yaml
```

## Fancy layout

The remainder of the changes in the [z2jh-config-fancy.yaml](z2jh-config-fancy.yaml) configuration file provides javascript and CSS "themes" to make the entry page a little more appealing. The provided example uses class-specific containers used at the University of Colorado. It should be obvious how to modify this for other containers since it's just using the profileList of standard Z2JH.

In order to enable the fancy layout, just upgrade Jupyterhub:
```
microk8s helm3 upgrade jhub jupyterhub/jupyterhub --version=0.10.5 --values=z2jh-config-fancy.yaml
```
