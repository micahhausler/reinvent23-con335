# Get role we've created
aws iam get-role --role-name $POD_ROLE_NAME --query Role.AssumeRolePolicyDocument | jq -C

# List the policies on the role
aws iam list-role-policies --role-name $POD_ROLE_NAME | jq -C

# Show the s3 policy
aws iam get-role-policy --role-name $POD_ROLE_NAME --policy-name s3Policy | jq -C .PolicyDocument.Statement[] | less -R

# Show the secretsmanager policy
aws iam get-role-policy --role-name $POD_ROLE_NAME --policy-name secretsmanagerPolicy  | jq -C .PolicyDocument.Statement[] | less -R

# List my EKS clusters
aws $ENDPOINT_FLAG eks list-clusters | jq -C .

# Install addon
aws eks $ENDPOINT_FLAG create-addon --cluster-name $CLUSTER_NAME --addon-name eks-pod-identity-agent --addon-version v1.0.0-eksbuild.1 | jq -C .

# Sleep until addon is ready
aws eks $ENDPOINT_FLAG wait addon-active --cluster-name $CLUSTER_NAME --addon-name eks-pod-identity-agent

# List associations
aws eks list-pod-identity-associations $ENDPOINT_FLAG --cluster-name $CLUSTER_NAME | jq -C .

# Create API
aws eks create-pod-identity-association $ENDPOINT_FLAG --cluster-name $CLUSTER_NAME --namespace default --service-account riv23-demo --role-arn $POD_ROLE | jq -C

