export AWS_CONFIG_FILE=`pwd`/aws_config.ini AWS_DEFAULT_PROFILE=base

# Get the cluster config
aws $ENDPOINT_FLAG eks describe-cluster --name $CLUSTER_NAME | jq .cluster.accessConfig

# View the existing configmap
kubectl get configmap -n kube-system aws-auth -o json | jq -C -r .data.mapRoles

# Look at the help text for updating
aws $ENDPOINT_FLAG eks update-cluster-config help | grep -A 4 authenticationMode

# Update the authentication mode
aws $ENDPOINT_FLAG eks update-cluster-config --name $CLUSTER_NAME --access-config authenticationMode=API_AND_CONFIG_MAP | jq -C

# Show access entries
aws $ENDPOINT_FLAG eks list-access-entries --cluster-name $CLUSTER_NAME | jq -C

# Get admin access entry
aws $ENDPOINT_FLAG eks describe-access-entry --cluster-name $CLUSTER_NAME --principal-arn $CLUSTER_CREATOR_ROLE_ARN | jq -C

# Get a node role
aws $ENDPOINT_FLAG eks describe-access-entry --cluster-name $CLUSTER_NAME --principal-arn $NODE_ROLE_ARN | jq -C

# Cannot roll back to configmap only
aws $ENDPOINT_FLAG eks update-cluster-config --name $CLUSTER_NAME --access-config authenticationMode=CONFIG_MAP

# View aws config
head -n 19 aws_config.ini

# Create an entry
aws $ENDPOINT_FLAG eks create-access-entry --cluster-name $CLUSTER_NAME --principal-arn $CLUSTER_VIEWER_ROLE_ARN --kubernetes-groups limited | jq -C

# Show built-in cluster roles
kubectl get clusterroles -l kubernetes.io/bootstrapping=rbac-defaults | grep -v 'system:'

# List acccess policies
aws $ENDPOINT_FLAG eks list-access-policies | jq -C .accessPolicies[].arn

# Associate viewer policy
aws $ENDPOINT_FLAG eks associate-access-policy --cluster-name $CLUSTER_NAME --principal-arn $CLUSTER_VIEWER_ROLE_ARN --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy --access-scope type=cluster | jq -C


AWS_DEFAULT_PROFILE=viewer

# Show identity
aws sts get-caller-identity | jq -C

# Get all pods
kubectl get pods --all-namespaces

# Create a configmap
kubectl create configmap demo-cm --from-literal=key=value

AWS_DEFAULT_PROFILE=base

# Update the authentication mode
aws $ENDPOINT_FLAG eks update-cluster-config --name $CLUSTER_NAME --access-config authenticationMode=API | jq -C

# Show base identity
aws sts get-caller-identity | jq -C

# Get all pods
kubectl get pods --all-namespaces

# Revoke creator from cluster
aws $ENDPOINT_FLAG eks delete-access-entry --cluster-name $CLUSTER_NAME --principal-arn $CLUSTER_CREATOR_ROLE_ARN | jq -C

# Fail to get all pods
kubectl get pods --all-namespaces
