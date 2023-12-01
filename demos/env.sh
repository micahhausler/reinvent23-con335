export JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=true
export ENDPOINT_FLAG=" "
export VPC_ID=""
# Role for EKS cluster control plane
export CLUSTER_ROLE=""
export NODE_ROLE=""
# Comma-separated subnet ids
export SUBNET_IDS=""
export POD_ROLE=""
export CLUSTER_NAME=${CLUSTER_NAME:-"gold-fish"}
export CLUSTER_VERSION=${CLUSTER_VERSION:-"1.28"}

# Cluster creator role arn
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export CLUSTER_VIEWER_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/RIV23ClusterViewer"
export CLUSTER_CREATOR_ROLE_ARN=""
export NODE_ROLE_ARN=""

