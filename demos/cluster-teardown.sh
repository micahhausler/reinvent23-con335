#!/usr/bin/env bash
set -ex
set -o pipefail

err_report() {
    echo "Exited with error on line $1"
}
trap 'err_report $LINENO' ERR


AWS_REGION=${AWS_REGION:-"us-west-2"}

CLUSTER_VERSION=${CLUSTER_VERSION:-"1.28"}
CLUSTER_NAME=${CLUSTER_NAME:-"blue-fish"}

# Used for pre-production URL overrides
#AWS_EKS_ENDPOINT=${AWS_EKS_ENDPOINT:-https://eks.us-west-2.amazonaws.com}
#ENDPOINT_FLAG="--endpoint $AWS_EKS_ENDPOINT"
ENDPOINT_FLAG=" "

# Delete system pods so that node group cleans up faster
kubectl --context $CLUSTER_NAME --namespace kube-system scale deployment/coredns --replicas=0
kubectl --context $CLUSTER_NAME --namespace kube-system delete daemonset kube-system
kubectl --context $CLUSTER_NAME --namespace kube-system delete daemonset eks-pod-identity-agent
kubectl --context $CLUSTER_NAME --namespace kube-system delete daemonset aws-node

NODEGROUPS=$(aws eks list-nodegroups \
    $ENDPOINT_FLAG \
    --cluster-name $CLUSTER_NAME | jq -r .nodegroups[] )
for NODEGROUP in $NODEGROUPS; do
    aws eks delete-nodegroup \
        $ENDPOINT_FLAG \
        --cluster-name $CLUSTER_NAME \
        --nodegroup-name $NODEGROUP
done
for NODEGROUP in $NODEGROUPS; do
    echo "Waiting on nodegroup $NODEGROUP deletion..."
    aws eks wait nodegroup-deleted \
        $ENDPOINT_FLAG \
        --cluster-name $CLUSTER_NAME \
        --nodegroup-name $NODEGROUP
done

CLUSTER_ARN=$(aws eks $ENDPOINT_FLAG describe-cluster --name $CLUSTER_NAME --query cluster.arn --output text )

aws eks ${ENDPOINT_FLAG} delete-cluster --name $CLUSTER_NAME
echo "Waiting on cluster deletion..."
aws eks ${ENDPOINT_FLAG} wait cluster-deleted --name $CLUSTER_NAME

kubectl config delete-user $CLUSTER_ARN
kubectl config delete-cluster $CLUSTER_ARN
kubectl config delete-context $CLUSTER_NAME
