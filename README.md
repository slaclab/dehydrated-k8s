# dehydrated-k8s

A simple dehydrated+nginx based docker container
and a helm chart for running dehydrated in a single namespace.

## Helm
This is a basic helm chart. You may install helm and, after
editing the values.yaml file appropriately and picking a name
for the deployment, probably where
 `name=$(echo "domain.example.com" | tr '.' '-')`

Run:
```
helm template $name . -f values-domain-example.com.yaml
```

That will render all the YAML files appropriately, and
you should just be able to `kubctl apply` them.


## Kubernetes
It is not stricly required, but you should create an PVC for 
the dehydrated accounts directory. This stores histories of 
certificates, Let's Encrypt account registration information,
etc...

At the frequency the job is currently defined (weekly), there's
not much of an issue if you don't, but you should be aware of 
some rate limiting information otherwise:
https://letsencrypt.org/docs/rate-limits/

### Creating PVCs in Rancher (and at NERSC)
At NERSC specifically, you should navigate to your project's workloads
page, then to the Volumes tab, and create a new volume in the expected
namespace you plan to use. After that, you should update your copy
of your values.yaml file.

### Tokens
It would be best to use RBAC Authorization and ServiceAccounts/
ClusterRoles for this deployment, if possible, so that the CronJob
can run with appropriate capabilities to only modify a secret.

In lieu of that, if your kubernetes cluster can create you a token,
you may specify that in the values file as well.
For Rancher, you should navigate to https://my-rancher.com/apikeys,
- https://rancher2.spin.nersc.gov/apikeys at NERSC, click `Add Key`, 
(scope it to cluster), and probably set it to never expire.

At that point, you can use it in the values.yaml file and a secret
will be generated as well as the volume claims.

## Spawning a cronjob
You may want to trigger the job after applying all the yaml files.

You can do that with kubectl:
```
kubectl create job --from cronjobs/${name}-dehydrated-k8s ${name}-init
```
