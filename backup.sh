# installing required tools
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl


curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# backing up namespaced resource
for n in $(kubectl get ns -o=name)
do
    dirlist+=("$n")
done

for i in ${dirlist[@]}
do
    echo $i
    mkdir -p $i
    q=$( echo $i | sed s/"namespace\/"// )
    echo 'getting resource from namespace' $q
    for d in $(kubectl api-resources --namespaced=true -o=name)
    do
        mkdir -p $i/$d
        for y in $(kubectl get $d -n $q -o=name)
        do 
            echo 'getting resource' $y 
            v=$(echo  $y | sed s/".*\/"// | sed s/"\/"//)
            kubectl get $d $v -n $q  -o=yaml   > ./$i/$d/$v.yaml
        done
    done
done

# backing up default namespaced resource


i=default-namespaced-resources
mkdir -p $i
for d in $(kubectl api-resources --namespaced=false -o=name)
do
    mkdir -p $i/$d
    echo $d
    for y in $(kubectl get $d -o=name)
    do
        echo 'getting resource' $y 
        v=$(echo  $y | sed s/".*\/"// | sed s/"\/"//)
        # echo kubectl get $d $v -n $q  -o=yaml  
        kubectl get $d $v -o=yaml   > ./$i/$d/$v.yaml
    # kubectl get $d -n $q  -o=yaml   > $i/$d/$d.yaml
    done
done


# ziping the folders
zipname=$(echo "k8s-manifest-backup-$(date +"%Y-%m-%d-%H-%M-%S").zip")
zip -r $zipname ./namespace ./non-namespaced-resources

# copying backup zip to s3 bucket 
aws s3 cp $zipname s3://tardis-ai-pipelines/manifest-backup/$zipname

