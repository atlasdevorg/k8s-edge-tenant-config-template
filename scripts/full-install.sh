#!/usr/bin/env bash

REPOSITORY_OWNER=$1 # e.g. neallclark
TENANT=$2 # e.g. acme
CLUSTER_NAME=$3
GIT_TOKEN=$4
API_HOST=$5 # e.g. localhost:44345

####### STEP 0: Register the cluster in Play 1st #######

####### STEP 1: install the tools we need if they aren't already #######
# flux2
curl -s https://toolkit.fluxcd.io/install.sh | sudo bash

# kubeseal
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.14.0/kubeseal-linux-amd64 -O kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal

####### STEP 2: Bootstrap flux into kubernetes #######
# TODO: create directories for PV's (This will depend on single node or multi node install)
export GITHUB_TOKEN=$GIT_TOKEN # Is this necessary? won't it pick it up anyway?
flux bootstrap github --owner=$REPOSITORY_OWNER --repository=k8s-edge-config-$TENANT --path=clusters/$CLUSTER_NAME --personal

####### STEP 3: Register the 2nd repository (The base config one) [This is a server side step] #######
#flux create source git base --url=https://github.com/$REPOSITORY_OWNER/k8s-edge-platform-config --branch=main --interval=1m
# CALL SERVER SIDE FUNCTION TO REGISTER BASE REPOSITORY INSTEAD
curl --location --request POST "https://$API_HOST/repository/$TENANT/edge/cluster/$CLUSTER_NAME/base/register"

####### STEP 4: Fetch and upload the public cert for the Sealed Secret Controller #######
echo 'Fetching the public cert for the sealed secret controller...'
while true
do
    kubeseal --fetch-cert --controller-name=sealed-secrets --controller-namespace=flux-system > ./pub-sealed-secrets.pem
    if [ -s "./pub-sealed-secrets.pem" ]; then
        echo 'Sealed Secret Public Key fetched successfully'
        break
    fi
    echo 'retry after 30 seconds...'
    sleep 30s
done

echo 'Uploading public key'
curl --location --request POST "https://$API_HOST/repository/$TENANT/edge/cluster/$CLUSTER_NAME/sealedsecret/publickey" \
--header 'Content-Type: text/plain' \
--data-binary '@pub-sealed-secrets.pem'

rm pub-sealed-secrets.pem

####### STEP 5: Create the Image Pull Secrets #######
curl --location --request POST "https://$API_HOST/repository/$TENANT/edge/cluster/$CLUSTER_NAME/sealedsecret/imagepullsecrets"


echo 'Install Done'
