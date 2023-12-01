#!/usr/bin/env bash

set -x

POD=$(kubectl get po -l app=riv23-demo  -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it $POD -- /bin/bash
