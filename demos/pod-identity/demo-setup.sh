#!/usr/bin/env bash

set -x

kubectl create configmap pod-setup \
    --from-file=init.sh=pod-config/init.sh \
    --from-file=.bashrc=pod-config/bashrc \
    --from-file=.vimrc=pod-config/vimrc \
    --from-literal=cluster-name=$(kubectl config current-context) \
    --from-literal=bucket-name=${BUCKET_NAME}

kubectl create configmap demo-scripts \
    --from-file=run.sh=pod-demo-scripts/run.sh \
    --from-file=s3-demo.sh=pod-demo-scripts/s3-demo.sh \
    --from-file=pod-env.sh=pod-demo-scripts/pod-env.sh \
    --from-file=blue-fish-demo.sh=pod-demo-scripts/blue-fish-demo.sh \
    --from-file=secretsmanager-demo.sh=pod-demo-scripts/secretsmanager-demo.sh

kubectl apply -f deployment.yaml

