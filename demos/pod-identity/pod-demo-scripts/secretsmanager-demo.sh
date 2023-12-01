# List all secrets
aws secretsmanager list-secrets | jq -C . 

# Create a random password
aws secretsmanager get-random-password --query RandomPassword --output text

# Store passwordas an env var
SECRET=$(aws secretsmanager get-random-password --query RandomPassword --output text)

# Create a secret without tags
aws secretsmanager create-secret --name ${CLUSTER_NAME}-super-secret --secret-string "$SECRET"

# Create a secret with the cluster tag
aws secretsmanager create-secret --name ${CLUSTER_NAME}-super-secret --secret-string "$SECRET" --tags Key=eks-cluster-name,Value=$CLUSTER_NAME | jq -C . 

# Get created secret
aws secretsmanager get-secret-value --secret-id ${CLUSTER_NAME}-super-secret | jq -C . 

# Untag cluster tag from secret
aws secretsmanager untag-resource --secret-id ${CLUSTER_NAME}-super-secret --tag-keys eks-cluster-name

# Delete secret
aws secretsmanager delete-secret --secret-id ${CLUSTER_NAME}-super-secret --force-delete-without-recovery

