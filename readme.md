# Deploy mssql

## Helm chart approach

```shell
export namespace=mssql
export apps_base_domain=apps.$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
helm upgrade mssql ./charts/mssql-linux -i --create-namespace -n ${namespace} -f ./values.yaml --set apps_base_domain=${apps_base_domain}
```
