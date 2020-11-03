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

stunnel stunnel-client.conf

sudo podman run -it --rm mcr.microsoft.com/mssql/rhel/server:2019-latest "bash"

/opt/mssql-tools/bin/sqlcmd -S 192.168.1.25,1433 -U SA -P "BaDEn2Ak5qE7etMaA4yK"

#Note this is just an example for testing connectivity to the ELB host will probably remove this - substitute the elb host and password with the generated ones
/opt/mssql-tools/bin/sqlcmd -S abade2b75403744409a872e4807f5889-345429645.us-east-2.elb.amazonaws.com,1433 -N -U SA -P "loXPpK40M1DoLvFpbAUp" -C

/opt/mssql-tools/bin/sqlcmd -S abade2b75403744409a872e4807f5889-345429645.us-east-2.elb.amazonaws.com,1433 -U SA -P "loXPpK40M1DoLvFpbAUp"

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
