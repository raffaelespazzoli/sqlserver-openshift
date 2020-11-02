# Deploy mssql

## Docs

<https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-encrypted-connections?view=sql-server-ver15>
<https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-configure-mssql-conf?view=sql-server-ver15#tls>

## Helm chart approach

```shell
oc apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.yaml
export namespace=mssql
export apps_base_domain=apps.$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
helm upgrade mssql ./charts/mssql-linux -i --create-namespace -n ${namespace} -f ./values.yaml --set apps_base_domain=${apps_base_domain}

#Test
sudo podman run -it --rm mcr.microsoft.com/mssql/rhel/server:2019-latest "bash"

#Note this is just an example - substitute the elb host and password with the generated ones
/opt/mssql-tools/bin/sqlcmd -S a4c5ff57003b549da94fdc24a4c28626-949138761.us-east-2.elb.amazonaws.com,1433 -N -U SA -P "qXFV7f76Q7JYniMsztzZ" -C
```

## Cleanup

```sh
helm delete mssql -n ${namespace}
oc delete pvc -n ${namespace} --all
```

## Run local

```sh
sudo podman run -i -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=r3dh4t1!" -p 1433:1433 --name sql1 -h sql1 -i --rm mcr.microsoft.com/mssql/rhel/server:2019-latest
# Test
sudo podman run -it --rm mcr.microsoft.com/mssql/rhel/server:2019-latest "bash"
/opt/mssql-tools/bin/sqlcmd -S 192.168.1.25,1433 -U SA -P "r3dh4t1!"
```
