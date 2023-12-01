BLUE_AID=$(aws eks list-pod-identity-associations $ENDPOINT_FLAG --cluster-name blue-fish --query associations[0].associationId --output text)
RED_AID=$(aws eks list-pod-identity-associations $ENDPOINT_FLAG --cluster-name red-fish --query associations[0].associationId --output text)

aws eks delete-pod-identity-association $ENDPOINT_FLAG --cluster-name blue-fish --association-id $BLUE_AID
aws eks delete-pod-identity-association $ENDPOINT_FLAG --cluster-name red-fish --association-id $RED_AID

aws eks $ENDPOINT_FLAG delete-addon --cluster-name blue-fish --addon-name eks-pod-identity-agent
aws eks $ENDPOINT_FLAG delete-addon --cluster-name red-fish --addon-name eks-pod-identity-agent

 aws eks $ENDPOINT_FLAG wait addon-deleted --cluster-name red-fish --addon-name eks-pod-identity-agent
