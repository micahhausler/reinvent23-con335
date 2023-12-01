
# EKS Pod Identity demo run steps

```bash
k config use-context red-fish

asciinema rec -i 5 final.cast
bash 
cd -
# TODO: remove the above lines from the final recording

k config get-contexts

./run.sh role-setup.sh

vi deployment.yaml

./demo-setup.sh

./exec.sh

./run.sh pod-env.sh

./run.sh s3-demo.sh

./run.sh secretesmanager-demo.sh

# exit red-fish pod

kubectl config use-context blue-fish

kubectl get po 

./exec.sh

./run.sh pod-env.sh

./run.sh blue-fish-demo.sh

# sanitize identifying strings
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
SESSION_NAME=$(aws sts get-caller-identity --query Arn --output text  | cut -f 3 -d/)

gsed -i -E "s/$SESSION_NAME/pod-identity-session/g" final.cast
gsed -i "s/$ACCOUNT_ID/111122223333/g" final.cast
gsed -i "s/$USER/micah/g" final.cast
gsed -i "s/$(hostname)/laptop/g" final.cast
gsed -i 's/riv23stack-clusterbucketf42acc2e-6pkvugk121bu/riv23-demo-bucket/g' final.cast
gsed -i 's/Riv23Stack-PodRole29A92600-bhksdj1P9xrs/riv23-pod-role/g' final.cast
gsed -i 's/SameProject//g' final.cast
gsed -i -E 's/ASIA\w{16}/ASIA1111222233334444/g' final.cast
gsed -i -E 's/AROA\w{17}/AROA0123456789012345678901/g' final.cast
gsed -i -E 's/eksnext/eks/g' final.cast
gsed -i -E 's/$ENDPOINT_FLAG //g' final.cast

# Convert to GIF
agg --theme asciinema --idle-time-limit 8 final.cast pod-identity.gif

# convert to MP4
ffmpeg -i pod-identity.gif -movflags faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" pod-identity.mp4
```