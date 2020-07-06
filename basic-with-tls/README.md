# Z2JH on k3s with TLS / HTTPS

As mentioned in the basic guide, Z2JH uses an ingress mechanism (`traefik`) and automatically configures Z2JH to get security certificates for that ingress.

K3s _also_ uses `traefik` as the ingress and TLS termination, meaning that any HTTPS traffic stops at the "system level" before getting to the "Z2JH level". That's why the basic setup disabled HTTPS connections.

Now, we're going to see how to enable HTTPS by telling the `traefik` of `k3s` what our certificates are. We'll be using `letsencrypt` to automate the certificates.

## Make certain you have a working basic environment

This guide builds on the past. Make certain you have a working environment with ingress, _etc_.

## First, install `cert-manager`

[cert-manager](https://cert-manager.io/) is a system for managing getting new TLS certificates. There are several good [tutorials on setting up `cert-manager` with `k3s`](https://opensource.com/article/20/3/ssl-letsencrypt-k3s) and we're going to cut to the chase for Z2JH.

Install `cert-manager` using the fast-and-dangerous method:
```
kubectl create namespace cert-manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.2/cert-manager.yaml
```
The `cert-manager` will install all of its stuff in the `cert-manager` namespace. This will make it easy to clean up later by just deleting that namespace.

## Second, create a certificate

`cert-manager` works by having you create two documents (an _issuer_ and a _certificate_) and then indicating to the `ingress` that you want to associate that certificate with a specific network endpoint.

The _issuer_ is one of many possible services that issue TLS security certificates. We'll use `letsencrypt` which is free. Letsencrypt has a "staging" service and a "production" service. The production service is rate limited meaning that if you make mistakes and hose things ups, it will block you for some period of time.

Once the issuer is configured, we can request a certificate. The actual certificate contents are stored in a `secret` called `jupyter-tls`. Later, we'll update the `ingress` to read the certificate from that secret.

* Modify [le-prod-issuer.yaml](le-prod-issuer.yaml) and change `email` from `contact@example.com` to your email address.
* Modify [le-prod-cert.yaml](le-prod-cert.yaml) and replace two instances of `host.example.com` with your hostname.

### Create Issuer
Now, create the issuer record:
```
kubectl apply -f le-prod-issuer.yaml
```
Then, check that the issuer is happy and running:
```
user@host:~/zero-to-jupyterhub-k3s/basic-with-tls$ kubectl get clusterissuer
NAME               READY   AGE
letsencrypt-prod   True    36s
```
The thing to look for is the word "True"

### Get Cert
Now, request a certificate using:
```
user@host:~/zero-to-jupyterhub-k3s/basic-with-tls$ kubectl apply -f mine-cert.yaml
```
You should inspect the certificate and wait for it to say "True":
```
user@host:~/zero-to-jupyterhub-k3s/basic-with-tls$ kubectl get cert
NAME          READY   SECRET        AGE
jupyter-tls   False   jupyter-tls   5s
```
This may take a little time but not more than a minute or so. If it takes more than 5 minutes, read [tutorials on setting up `cert-manager` with `k3s`](https://opensource.com/article/20/3/ssl-letsencrypt-k3s) on how to debug things.

At this point, you should have a secret holding your certificate:
```
user@host:~/zero-to-jupyterhub-k3s/basic-with-tls$ kubectl get secret jupyter-tls
NAME          TYPE                DATA   AGE
jupyter-tls   kubernetes.io/tls   3      3m41s
```

## Third, update the ingress to use your certificate

Now,
* Modify [jupyter-ingress-tls.yaml](jupyter-ingress-tls.yaml) and replace two instances of `host.example.com` with your hostname.

and then update the `ingress`:
```
user@host:~/zero-to-jupyterhub-k3s/basic-with-tls$ kubectl apply -f le-prod-ingress.yaml 
ingress.networking.k8s.io/jupyter-ingress configured
```

Now, when you visit your host using `https` you should have a secure connection. You may need to restart your browser or try an alternate browser if the old certificate (which uses a dummy certificate for `https://example.com`) is confusing your browser.

## Cleaning up

We used a quick-and-easy way to install `cert-manager`, so you can't use `helm` to delete it.
However, you can uninstall `cert-manager` by deleting the namespace:
```
kubectl delete namespace cert-manager
```
You can clean up the certificates and issues using
```
kubectl delete secret jupyter-tls
kubectl delete cert jupyter-tls
kubectl delete clusterissuer letsencrypt-prod
```
and then clean up the others as in the basic guide.
