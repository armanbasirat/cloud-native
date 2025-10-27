# ===========================================
# Filebeat DaemonSet for Kubernetes
# with Logstash Output
# ===========================================

apiVersion: v1
kind: Namespace
metadata:
  name: logging
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: filebeat
  namespace: logging
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: filebeat
rules:
  - apiGroups: [""]
    resources:
      - pods
      - namespaces
      - nodes
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: filebeat
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: filebeat
subjects:
  - kind: ServiceAccount
    name: filebeat
    namespace: logging
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: logging
  labels:
    k8s-app: filebeat
data:
  filebeat.yml: |-
    filebeat.autodiscover:
      providers:
        - type: kubernetes
          node: ${NODE_NAME}
          hints.enabled: true
          hints.default_config:
            type: container
            paths:
              - /var/log/containers/*${data.kubernetes.container.id}.log
          templates:
            - condition:
                equals:
                  kubernetes.namespace: "kube-system"
              config:
                - type: container
                  paths:
                    - /var/log/containers/*${data.kubernetes.container.id}.log
                  fields:
                    cluster: ${CLUSTER_NAME}

    processors:
      - add_host_metadata: {}
      - add_cloud_metadata: {}
      - add_kubernetes_metadata:
          in_cluster: true
      - add_fields:
          target: ''
          fields:
            cluster_name: ${CLUSTER_NAME}

    # Send data to external Logstash
    output.logstash:
      hosts: ["logstash.yourdomain.com:5044"]
      ssl.enabled: true
      ssl.verification_mode: "certificate"

    setup.template.name: "virtual"
    setup.template.pattern: "virtual-*"
    setup.ilm.enabled: false

    # Logging settings
    logging.level: info
    logging.to_files: true
    logging.files:
      path: /var/log/filebeat
      name: filebeat
      keepfiles: 7
      permissions: 0644
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: logging
  labels:
    k8s-app: filebeat
spec:
  selector:
    matchLabels:
      k8s-app: filebeat
  template:
    metadata:
      labels:
        k8s-app: filebeat
    spec:
      serviceAccountName: filebeat
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirstWithHostNet
      hostNetwork: true
      containers:
        - name: filebeat
          image: docker.elastic.co/beats/filebeat:8.14.0
          args: ["-e", "-strict.perms=false"]
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            # 👇 Set this per cluster
            - name: CLUSTER_NAME
              value: "core"    # change to "payment" or "digital" on other clusters
          securityContext:
            runAsUser: 0
          volumeMounts:
            - name: config
              mountPath: /usr/share/filebeat/filebeat.yml
              subPath: filebeat.yml
              readOnly: true
            - name: varlog
              mountPath: /var/log
            - name: varlibdockercontainers
              mountPath: /var/lib/docker/containers
              readOnly: true
      volumes:
        - name: config
          configMap:
            name: filebeat-config
            items:
              - key: filebeat.yml
                path: filebeat.yml
        - name: varlog
          hostPath:
            path: /var/log
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers
