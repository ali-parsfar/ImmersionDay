#!/bin/bash
# Description = This bash script > With using awscli , eksctl , helm , kubectl , and creates a simple eks cluster with AWS-LB-CTL and some sample of Ingress and service .
# HowToUse = Please update the VARIABLES section , and run it with "./run.sh" command in CloudShell. 
# Duration = Around 15 minutes
#
# Some useful links:
# https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.8/examples/echo_server/
# How do I automatically discover the subnets that my Application Load Balancer uses in Amazon EKS? = labels to subnets
# https://docs.aws.amazon.com/eks/latest/userguide/cluster-iam-role.html
# https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEKSClusterPolicy.html
# https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###






### Variables:
export REGION=us-east-1
export CLUSTER_VER=1.29
export CLUSTER_NAME=ImmersionDay
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export ACC=$AWS_ACCOUNT_ID
export AWS_DEFAULT_REGION=$REGION

echo " 
 ### 0- CloudShell Prepration:
#############################################################
#### install Helm , eksctl in CloudShell
"

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz"
tar -xzf eksctl_Linux_amd64.tar.gz -C /tmp && rm eksctl_Linux_amd64.tar.gz
sudo mv /tmp/eksctl /usr/local/bin

curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh


echo " #### Who am I ? "
aws sts get-caller-identity 

echo " #### AWSCLI version:"
aws --version
echo " "

echo " #### KUBECTL version:"
kubectl version --client=true
echo " "

echo " #### AWSCLI version:"
eksctl version
echo " "

echo " #### HELM version:"
helm version
echo " "


echo " 
#### PARAMETERES IN USER >>> 
CLUSTER_NAME=$CLUSTER_NAME  
CLUSTER_VER=$CLUSTER_VER
REGION=$REGION 
AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID

"

if [[ $1 == "cleanup" ]] ;
then 


### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
echo " 
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
 ### Doing Cleanup 
# delete all SVCs and INGs
# Cleanup IRSA  
# Delete cluster 
 "
# Do Cleanup

kubectl delete -n echoserver ing --all
kubectl delete -n game-2048 ing --all
kubectl delete   ing --all
kubectl delete  svc --all


sleep 60 
eksctl delete iamserviceaccount --region=$REGION --cluster=$CLUSTER_NAME --namespace=kube-system --name=aws-load-balancer-controller 
kubectl  -n kube-system describe sa aws-load-balancer-controller


sleep 60 
eksctl delete cluster $CLUSTER_NAME

exit 1
fi;


### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
echo "
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
 ### 1- Create cluster "

eksctl create cluster  -f - <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: $CLUSTER_NAME
  region: $REGION
  version: "$CLUSTER_VER"

managedNodeGroups:
  - name: mng
    privateNetworking: true
    desiredCapacity: 2
    instanceType: t3.medium
    labels:
      worker: linux
    maxSize: 3
    minSize: 0
    volumeSize: 20
#    ssh:
#      allow: true
#      publicKeyPath: AliSyd

kubernetesNetworkConfig:
  ipFamily: IPv4 # or IPv6

addons:
  - name: vpc-cni
  - name: coredns
  - name: kube-proxy

iam:
  withOIDC: true

cloudWatch:
  clusterLogging:
    enableTypes:
      - "*"

EOF

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
echo "
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
 ### 2- kubeconfig  : "
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
echo " 
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
### 3- Check cluster node and infrastructure pods  : "
kubectl get node
kubectl -n kube-system get pod 
kubectl   get crd > crd-0.txt

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
echo "
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
 ### 3- create iamserviceaccount  : 
 "
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.8.2/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json


eksctl create iamserviceaccount \
--region=$REGION \
--cluster=$CLUSTER_NAME \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::$ACC:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--approve

kubectl  -n kube-system describe sa aws-load-balancer-controller > aws-load-balancer-controller_sa.yaml 


### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
echo "
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
 ### 4 - Install lbc with helm  : 
 "
helm repo add eks https://aws.github.io/eks-charts

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
-n kube-system \
--set clusterName=$CLUSTER_NAME \
--set serviceAccount.create=false \
--set serviceAccount.name=aws-load-balancer-controller \
--set region=$REGION 

sleep 30

kubectl  -n kube-system logs  -l app.kubernetes.io/name=aws-load-balancer-controller | tee -a  lbc_logs-0.log

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
echo " 
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
 ### 5- Deploy all the echoserver resources (namespace, service, deployment , ingress) from already checked file  "

kubectl apply -f echoserver

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
echo " 
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
 ### 6- Deploy all the echoserver resources (namespace, service, deployment , ingress) from already checked file  "

kubectl apply -f game2048

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
echo " 
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
 ### 7- Deploy all the echoserver resources (namespace, service, deployment , ingress) from already checked file  "

kubectl apply -f nginxweb

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
echo " 
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
 ### 8- Deploy all the echoserver resources (namespace, service, deployment , ingress) from already checked file  "

kubectl apply -f nginx-nlb-svc

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
echo "
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
 ### 9 - Recording configs and status  "

sleep 30
 STAT=`date +%s`
 mkdir $STAT
cp iam-policy.json $STAT
kubectl -n kube-system logs  -l app.kubernetes.io/name=aws-load-balancer-controller > $STAT/lbc_logs-1.log
kubectl -n kube-system get pod  -l app.kubernetes.io/name=aws-load-balancer-controller -o yaml > $STAT/lbc_oyaml.log
kubectl get ingress -A -o wide > $STAT/ings.txt
kubectl get svc -A -o wide > $STAT/svcs.txt
kubectl describe targetgroupbindings -A > $STAT/tgBindings.yaml 
kubectl   get crd > $STAT/crd.txt

mkdir $STAT/echoserver
kubectl  -n echoserver describe ingress echoserver > $STAT/echoserver/ingress.yaml
kubectl  -n echoserver describe svc > $STAT/echoserver/vc.yaml
kubectl  -n echoserver describe ep > $STAT/echoserver/ep.yaml
kubectl  -n echoserver describe pod > $STAT/echoserver/pod.yaml
kubectl  -n echoserver describe targetgroupbindings > $STAT/echoserver/tgBinding.yaml 

mkdir $STAT/game-2048
kubectl  -n game-2048 describe ingress echoserver > $STAT/game-2048/ingress.yaml
kubectl  -n game-2048 describe svc > $STAT/game-2048/svc.yaml
kubectl  -n game-2048 describe ep > $STAT/game-2048/ep.yaml
kubectl  -n game-2048 describe ep > $STAT/game-2048/pod.yaml
kubectl  -n game-2048 describe targetgroupbindings > $STAT/game-2048/tgBinding.yaml 

$STAT/default
kubectl   describe ingress echoserver > $STAT/default/nginxweb_ingress.yaml
kubectl   describe svc > $STAT/default/svc.yaml
kubectl   describe pod > $STAT/default/pod.yaml
kubectl   describe ep > $STAT/default/ep.yaml
kubectl   describe targetgroupbindings > $STAT/default/tgBinding.yaml 

kubectl get svc -A -o wide
kubectl get ingress -A -o wide
