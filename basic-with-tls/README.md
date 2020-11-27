# Z2JH on microk8s with TLS / HTTPS

As mentioned in the basic guide, Z2JH uses an ingress mechanism (`traefik`) and automatically configures Z2JH to get security certificates for that ingress.

When using `microk8s` configured with `metallb` implementing the `LoadBalancer` service time, you can just directly use the Z2JH setup.

## Update the config to use security

The Z2JH chart supports using [letsencrypt](https://letsencrypt.org/) to automatically generate a TLS certificte for your host. You need to provide the hostname (e.g. `beast.cs.colorado.edu` in this example) and your email (e.g. `grunwald@colorado.edu` in this example).
```
  service:
    type: LoadBalancer
  https:
    enabled: true
    hosts:
      - "beast.cs.colorado.edu"
    letsencrypt:
      contactEmail: "grunwald@colorado.edu"
```
Then, you should be able to update your Helm configuration
```
microk8s helm3 upgrade jhub jupyterhub/jupyterhub --version=0.10.5 --values=z2jh-config.yaml
```
It may take a few minutes for your `LoadBalancer` to register an address,
and when you check the service endpoints, you should now see it serving port 443 as well as port 80:
```
grunwald@beast:~/zero-to-jupyterhub-microk8s/basic-with-tls$ microk8s kubectl get svc
NAME           TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                      AGE
kubernetes     ClusterIP      10.152.183.1     <none>          443/TCP                      5h40m
proxy-api      ClusterIP      10.152.183.111   <none>          8001/TCP                     47m
hub            ClusterIP      10.152.183.226   <none>          8081/TCP                     47m
proxy-http     ClusterIP      10.152.183.134   <none>          8000/TCP                     10s
proxy-public   LoadBalancer   10.152.183.5     192.12.242.33   443:31798/TCP,80:30800/TCP   47m
```

Now, when you visit your host using `https` you should have a secure connection. You may need to restart your browser or try an alternate browser if the old certificate is confusing your browser.

The letsencrypt certificate will be automatically renewed as needed.