# To port-forward a pod 
`kubectl --context rancher-desktop -n srmvcas port-forward pod/srmvcas-db-coord-0 5431:5432`

# To get password
`kubectl --context rancher-desktop -n srmvcas get secret srmvcas-db -o jsonpath='{.data.superuser-password}' | base64 -d`