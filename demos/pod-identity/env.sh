export JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=true

export BUCKET_NAME=""
export POD_ROLE=""
export POD_ROLE_NAME=$(echo $POD_ROLE | cut -f2 -d/)
export CLUSTER_NAME=${CLUSTER_NAME:-"red-fish"}
export AWS_REGION=${AWS_REGION:-"us-west-2"}
export ENDPOINT_FLAG=" "
