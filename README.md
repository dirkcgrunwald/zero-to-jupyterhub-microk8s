# Zero-to-Jupyterhub on k3s

`k3s` is version of Kubernetes that is simple to install. This repo contains instructions and sample files to install [Zero-to-JupyterHub](https://zero-to-jupyterhub.readthedocs.io/en/latest/). This can be useful for setting up a testing environment or an environment for a tutorial or class.

There are three setup directions that build on each other. 
* [Jupyterhub w/o TLS](basic/README.md)
* [Adding in TLS for HTTPS or secure connections](basic-with-ssh/README.md)
* [Adding in NFS including shared volumes](basic-with-nfs-volumes/README.md)

The assumptions in each guide is that you have a Linux computer. For the TLS guide, you need to have a public IP.