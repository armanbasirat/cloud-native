```
mc alias set minio1 https://minio1.example.com minioadmin minioadmin
mc alias set minio2 https://minio2.example.com minioadmin minioadmin
```

```
mc admin info minio1
mc admin info minio2
```

```
mc replicate add minio1 \
  --remote-service minio2 \
  --replicate "delete,delete-marker,existing-objects" \
  --all
```

```
mc replicate add minio2 \
  --remote-service minio1 \
  --replicate "delete,delete-marker,existing-objects" \
  --all
```

```
mc replicate ls minio1
mc replicate ls minio2
```