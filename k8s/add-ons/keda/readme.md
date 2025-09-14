```diff
helm upgrade --install keda keda-2.17.2 \
  --namespace keda \
  --create-namespace

helm ls -n keda
```

```diff
helm upgrade --install keda-add-ons-http keda-add-ons-http-0.10.0 \
  --namespace keda \
  --create-namespace

helm ls -n keda
```
