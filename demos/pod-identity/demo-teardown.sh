#!/usr/bin/env bash

set -x

kubectl delete deployment riv23-demo
kubectl delete sa riv23-demo
kubectl delete configmap pod-setup
kubectl delete configmap demo-scripts
