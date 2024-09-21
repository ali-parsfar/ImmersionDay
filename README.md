## What is it:
This bash script , With using awscli , eksctl , helm , kubectl , and creates a simple eks cluster with AWS-LB-CTL and some sample of Ingress and service .

#### Important= You will charge for Load balncer and EKS cluster during this workshop. Please make sure you clean it up completely at the end . 

## How To Use:
- Please update the VARIABLES section of run.sh file
- The make run.sh executable with " chmod +x run.sh "
- Then run it with "./run.sh" command in CloudShell. 

## Duration: 
Around 15 minutes

## Cleanup:
There is a cleanup section in script , that can be activated by running " ./run.sh cleanup " command :
 - It deletes all SVCs and INGs in the cluster
 - It cleans up IRSA  
 - And finally deletes the cluster

#### NOTE = It is that cluster not deleted correctly , to prevent any extra charges , please dlete Cloudformation stack with similar name to cluster name to make sure everything had dleted .   


