# b64 endode 1Mb of random data
head -c $((1<<20)) /dev/urandom | base64 -w0 > /tmp/random-data

# Copy that data to the S3 bucket
aws s3 cp /tmp/random-data s3://$BUCKET_NAME/data/

# Copy that data to the S3 bucket, under the CLUSTER_NAME path
aws s3 cp /tmp/random-data s3://$BUCKET_NAME/data/$CLUSTER_NAME/random-data

# List the bucket
aws s3 ls --recursive s3://$BUCKET_NAME

# Copy the logs from the bucket
aws s3 cp s3://$BUCKET_NAME/logs/687ae98c-a9fb-4da7-a572-ac5ead5de0c7/bash_history /tmp/bash_history

# Upload pod logs
aws s3 cp ~/.bash_history s3://$BUCKET_NAME/logs/$POD_UID/bash_history


