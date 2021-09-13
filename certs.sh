#!/bin/bash
####  This script needs bash4 or above. Dependencies require Python3  ####
# You can use https://cert-manager.io/ for managing certs on K8s clusters but I (andrew) think its massively overcomplicated and fragile.

### Dependancies ###
#  Bash 4
#  Python3
#  jq
#  kubectl
#  pip3 install certbot certbot-dns-route53 awscli

### Copying certificates between namespaces ###
# This command wants to run in your deployment somewhere. It expects the certs to be in the default namespace.
# There used to be an "--export" flag in kubectl which made this much easier but they depriciated it.
# jq is used to strip out some metadata
# kubectl get secret wildcard-devops-wizard-com -o json | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","selfLink","uid"])' | kubectl apply -n master -f -

# Find out where the script is running
SCRIPT_DIR=$(dirname "$0")
TLD=542.cloud
NAMESPACE=default
# TLD is Top level domain e.g. 'wtf.com'
if [[ ! -v 'TLD' ]]; then
    echo "var TLD is empty or undefined. Please set \$TLD as the top level domain"
    exit 1
fi

# Check that we have a K8s namespace to put the cert into.
if [[ ! -v 'NAMESPACE' ]]; then
    echo "var NAMESPACE is empty or undefined. Please set \$NAMESPACE so I know which k8s namespace to place the cert in."
    exit 1
fi

# Check that we can connect to AWS with local credentials.
if aws route53 list-hosted-zones > /dev/null; then
    echo "Connection to AWS route 53 succeded"
else
    echo "Connection to AWS route 53 failed. Please ensure AWS credentials are in place"
    exit 1
fi

# Make a directory where we can put out Certs.
mkdir -p $TLD

# create fake cert if --fake flag is passed.
if [[ $* == *--fake ]]; then
# Make a directory where we can put out Certs.
DIR=$SCRIPT_DIR/$TLD-fake
mkdir -p $DIR
certbot certonly \
      --test-cert \
      --dns-route53 -d *.$TLD \
      --config-dir $DIR \
      --work-dir $DIR \
      --logs-dir $DIR \
      -m andrew.holway@guest.hpi.de \
      --agree-tos -n

# create real cert if --real flag is passed.
elif [[ $* == *--real ]]; then
DIR=$SCRIPT_DIR/$TLD-real
mkdir -p $DIR
certbot certonly \
      --dns-route53 -d *.$TLD \
      --config-dir $DIR \
      --work-dir $DIR \
      --logs-dir $DIR \
      -m andrew.holway@guest.hpi.de \
      --agree-tos -n
else
echo "You need to choose between a fake or real ssl cert. Please pass --fake or --real flags"
exit 1
fi

# Put our certs into our namespace.
kubectl create secret tls wildcard-${TLD/./-} \
      --key $DIR/live/$TLD/privkey.pem \
      --cert $DIR/live/$TLD/fullchain.pem \
      --save-config \
      -n $NAMESPACE