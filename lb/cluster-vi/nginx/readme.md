apt install -y docker.io docker-compose
cd /app/workspace/nginx
docker-compose up -d



## Create certificate without root CA

cat > san.cnf <<EOF
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[dn]
C  = IR
ST = Tehran
L  = Tehran
O  = Dotin
OU = Virtual Dep.
CN = *.test.local

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.test.local
DNS.2 = test.local
EOF


openssl req -new -nodes -out wildcard.csr -newkey rsa:2048 -keyout wildcard.key -config san.cnf
openssl x509 -req -in wildcard.csr -signkey wildcard.key -out wildcard.crt -days 365 -extensions req_ext -extfile san.cnf
openssl x509 -in wildcard.crt -text -noout | grep -A 1 "Subject Alternative Name"





## Create certificate with root CA

openssl genrsa -out myCA.key 4096
openssl req -x509 -new -nodes -key myCA.key -sha256 -days 3650 -out myCA.crt -subj "/C=IR/ST=Tehran/L=Tehran/O=Dotin/OU=Virtual Dep./CN=virtual Root CA"


cat > wildcard.cnf <<EOF
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[dn]
C  = IR
ST = Tehran
L  = Tehran
O  = Dotin
OU = Virtual Dep.
CN = *.test.local

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.test.local
DNS.2 = test.local
EOF


openssl req -new -nodes -out wildcard.csr -newkey rsa:2048 -keyout wildcard.key -config wildcard.cnf

openssl x509 -req -in wildcard.csr -CA myCA.crt -CAkey myCA.key -CAcreateserial \
-out wildcard.crt -days 825 -sha256 -extfile wildcard.cnf -extensions req_ext
