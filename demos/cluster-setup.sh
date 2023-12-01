#!/usr/bin/env bash
set -ex
set -o pipefail

err_report() {
    echo "Exited with error on line $1"
}
trap 'err_report $LINENO' ERR


AWS_REGION=${AWS_REGION:-"us-west-2"}

CLUSTER_VERSION=${CLUSTER_VERSION:-"1.28"}
CLUSTER_NAME=${CLUSTER_NAME:-"gold-fish"}

# Used for pre-production URL overrides
#AWS_EKS_ENDPOINT=${AWS_EKS_ENDPOINT:-https://eks.us-west-2.amazonaws.com}
#ENDPOINT_FLAG="--endpoint $AWS_EKS_ENDPOINT"
ENDPOINT_FLAG=" "

CREATED_CLUSTER=$(aws eks $ENDPOINT_FLAG list-clusters --query 'clusters[?contains(@,`'$CLUSTER_NAME'`) == `true`]' --output text)
echo "CREATED_CLUSTER=$CREATED_CLUSTER"
if [ "$CREATED_CLUSTER" = "" ]; then
    aws eks create-cluster --name $CLUSTER_NAME \
        ${ENDPOINT_FLAG} \
        --tags karpenter.sh/discovery=$CLUSTER_NAME \
        --role-arn ${CLUSTER_ROLE} \
        --resources-vpc-config subnetIds=${SUBNET_IDS} \
        --kubernetes-version ${CLUSTER_VERSION} \
		--logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'
fi

echo "Sleeping until cluster is ready"
aws eks $ENDPOINT_FLAG wait cluster-active --name $CLUSTER_NAME

CLUSTER_ARN=$(aws eks $ENDPOINT_FLAG describe-cluster --name $CLUSTER_NAME --query cluster.arn --output text )
aws $ENDPOINT_FLAG eks tag-resource --resource-arn $CLUSTER_ARN --tags karpenter.sh/discovery=$CLUSTER_NAME

NODEGROUP_NAME="$CLUSTER_NAME-nodegroup1"
CREATED_NODEGROUP=$(aws eks $ENDPOINT_FLAG list-nodegroups --cluster-name $CLUSTER_NAME --query 'nodegroups[?contains(@,`'$NODEGROUP_NAME'`) == `true`]' --output text)
echo "CREATED_NODEGROUP=$CREATED_NODEGROUP"
if [ "$CREATED_NODEGROUP" = "" ]; then
    aws eks create-nodegroup --cluster-name $CLUSTER_NAME \
        $ENDPOINT_FLAG \
        --nodegroup-name $CLUSTER_NAME-nodegroup1 \
        --ami-type AL2_x86_64 \
        --scaling-config desiredSize=1,minSize=1,maxSize=2 \
        --capacity-type ON_DEMAND \
        --node-role ${NODE_ROLE} \
        --subnets $(echo $SUBNET_IDS | tr ',' ' ' ) | jq .
fi


echo "Sleeping until nodegroup is ready"
aws eks $ENDPOINT_FLAG wait nodegroup-active --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP_NAME

aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME $ENDPOINT_FLAG
kubectl config rename-context $CLUSTER_ARN $CLUSTER_NAME

