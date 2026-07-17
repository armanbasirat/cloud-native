### Listing Available API Groups in Your Cluster

```diff
(echo -e "NAME\tAPI-GROUP\tVERSION"; \
kubectl api-resources --no-headers | \
awk '{ 
  if (NF==5) { 
    name = $1; 
    apiversion = $3 
  } else if (NF==4) { 
    name = $1; 
    apiversion = $2 
  } 
  split(apiversion, a, "/"); 
  if (a[2] == "") { 
    group = "core"; 
    version = a[1] 
  } else { 
    group = a[1]; 
    version = a[2] 
  } 
  print name "\t" group "\t" version 
}') | column -t
```