# Create a secret with the cluster tag
aws secretsmanager create-secret --name ${CLUSTER_NAME}-super-secret --secret-string "super-secret-sauce" --tags Key=eks-cluster-name,Value=$CLUSTER_NAME | jq -C . 

# List all secrets
aws secretsmanager list-secrets | jq -C . 

# Get created secret
aws secretsmanager get-secret-value --secret-id ${CLUSTER_NAME}-super-secret | jq -C .

# Get red-fish secret
aws secretsmanager get-secret-value --secret-id red-fish-super-secret 

# Get another pod logs
aws s3 cp s3://${BUCKET_NAME}/logs/1e4b7cf0-85cc-42b4-8d29-bfed055bac02/bash_history /tmp/bash_history

# Get config/CLUSTER/NAMESPACE/SERVICE_ACCOUNT/
aws s3 cp s3://${BUCKET_NAME}/config/$CLUSTER_NAME/$POD_NAMESPACE/$POD_SERVICE_ACCOUNT/surprise /tmp/surprise

cat /tmp/surprise

# Get credentials like the SDK
curl -s $AWS_CONTAINER_CREDENTIALS_FULL_URI -H "Authorization: $(cat $AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE)" |  jq '{AccessKeyId: .AccessKeyId, SecretAccessKey: "SECRET", Token: "TOKEN", Expiration: .Expiration }'
