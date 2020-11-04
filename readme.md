# Deploy mssql

## Docs

<https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-encrypted-connections?view=sql-server-ver15>
<https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-configure-mssql-conf?view=sql-server-ver15#tls>

## Deploy with stunnel sidecar

This approach uses an stunnel sidecar to present the certificate. Locally, we run an stunnel client which will originate tls + SNI and use the Openshift route to connect to the sidecar which terminates tls before forwarding to the mssql container in the same pod.

```shell
oc apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.yaml
export namespace=mssql
export apps_base_domain=apps.$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
helm upgrade mssql ./charts/mssql-linux-stunnel -i --create-namespace -n ${namespace} -f ./values.yaml --set apps_base_domain=${apps_base_domain}
```

Test using sqlcmd ms tools by running a local container (or just install the sqlcmd tool to your workstation)

```sh
export password=$(oc get secret mssql-mssql-linux-secret -o jsonpath='{.data.sapassword}' | base64 -d)

echo $password # make note of this for running in the container

export ip_address=192.168.1.25 # use ifconfig to get your own ip address assigned to your machine

echo $ip_address # make note of this for later

# edit the stunnel-client.conf file and set the connect variable to the openshift route host
echo ${namespace}-mssql-linux.${apps_base_domain}:443 # the host name
# example connect host in stunnel-client.conf
connect=mssql-mssql-linux.apps.cluster-4331.4331.sandbox258.opentlc.com:443

# start stunnel
stunnel stunnel-client.conf

# open a new terminal

# run a container that has sqlcmd tool - if you don't already have sqlcmd tool installed on your workstation
sudo podman run -it --rm mcr.microsoft.com/mssql/rhel/server:2019-latest "bash"
export ip_address= # paste from previous
export password= # paste from previous
/opt/mssql-tools/bin/sqlcmd -S ${ip_address},1433 -U SA -P ${password}
```

## Deploy with certificate presented by the mssql container

You need to use an external load balancer to connect to this container since an openshift route won't work with this configuration.

```shell
oc apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.yaml
export namespace=mssql
export apps_base_domain=apps.$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
helm upgrade mssql ./charts/mssql-linux -i --create-namespace -n ${namespace} -f ./values.yaml --set apps_base_domain=${apps_base_domain}
```

Test using sqlcmd ms tools by running a local container (or just install the sqlcmd tool to your workstation)

```sh
export elb_host=$(oc get svc mssql-mssql-linux -n ${namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $elb_host # make note of this for later

export password=$(oc get secret mssql-mssql-linux-secret -o jsonpath='{.data.sapassword}' | base64 -d)
echo $password # make note of this for later

sudo podman run -it --rm mcr.microsoft.com/mssql/rhel/server:2019-latest "bash"
export elb_host= # paste from previous
export password= # paste from previous
/opt/mssql-tools/bin/sqlcmd -S ${elb_host},1433 -N -U SA -P ${password} -C
```

## Deploy with certificate presented by the mssql container and openshift route

For this configuration you need and application that can originate TLS with SNI for the Openshift passthrough route to work. SNI is a requirement for HAProxy.

```shell
oc apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.yaml
export namespace=mssql
export apps_base_domain=apps.$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
helm upgrade mssql ./charts/mssql-linux-route -i --create-namespace -n ${namespace} -f ./values.yaml --set apps_base_domain=${apps_base_domain}
```

> TODO: we need an example application that can origiate the TLS with SNI to test this configration.

## Cleanup

```sh
helm delete mssql -n ${namespace}
oc delete pvc -n ${namespace} --all
```

## Misc

### Run local

```sh
sudo podman run -i -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=r3dh4t1!" -p 1433:1433 --name sql1 -h sql1 -i --rm mcr.microsoft.com/mssql/rhel/server:2019-latest
# Test
sudo podman run -it --rm mcr.microsoft.com/mssql/rhel/server:2019-latest "bash"
/opt/mssql-tools/bin/sqlcmd -S 192.168.1.25,1433 -U SA -P "r3dh4t1!"
```
