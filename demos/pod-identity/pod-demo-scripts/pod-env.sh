# Get caller identity
aws sts get-caller-identity

# Get environment
env | grep -E 'POD|CLUSTER|AWS'| sort
