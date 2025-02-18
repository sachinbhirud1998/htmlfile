Cross-Region Deployable Pipeline Creation Guide
Introduction
This document provides comprehensive instructions for creating an automated pipeline using AWS CodeBuild and CodePipeline. The pipeline builds a Docker image from a GitHub repository (https://github.com/sachinbhirud1998/htmlfile.git), pushes it to Amazon ECR, and deploys it to Amazon EKS clusters in multiple AWS regions—all from a single branch. The configuration includes proper IAM roles, cross-region deployment steps, and essential EKS add-ons.
Table of Contents
1.Getting Started in the AWS Console
2.Installing Required Tools
3.Configuring IAM Roles and Policies
4.Creating Amazon ECR Repositories
5.Creating Amazon EKS Clusters in Multiple Regions
6.Installing EKS Add-ons
7.Preparing Configuration Files
8.Creating and Deploying the Pipeline
9.Verifying the Deployment
10.Troubleshooting Tips
Getting Started in the AWS Console
1.Log in to the AWS Management Console:
oOpen your web browser and navigate to https://console.aws.amazon.com/
oEnter your credentials to access your AWS account
2.Set your default region:
oIn the top right corner of the console, select your preferred region (e.g., us-west-2)
Installing Required Tools
Ensure the following tools are installed on your local machine if you need to perform administrative tasks outside the console:
AWS CLI
Installation Guide: Follow the AWS CLI installation instructions for your operating system.
kubectl
Installation Guide: Follow the kubectl installation guide for your operating system.
Configuring IAM Roles and Policies
Create a CodeBuild Service Role
1.Navigate to the IAM Console:
oClick on the "Services" dropdown at the top of the AWS Console
oSelect "IAM" under the "Security, Identity, & Compliance" section
2.Create a New Role:
oIn the left navigation pane, click "Roles"
oClick the "Create role" button
oSelect "AWS service" as the trusted entity type
oChoose "CodeBuild" from the use case list
oClick "Next: Permissions"
3.Attach Policies:
oIn the search box, type "AmazonEC2ContainerRegistryPowerUser" and select it
oSearch for "AmazonEKSClusterPolicy" and select it
oClick "Next: Tags"
o(Optional) Add any desired tags
oClick "Next: Review"
oEnter a role name (e.g., CodeBuildServiceRole-MultiRegion)
oClick "Create role"
4.Add an Inline Policy:
oFrom the roles list, click on the role you just created
oIn the "Permissions" tab, click "Add inline policy"
oSelect the "JSON" tab
oPaste the following policy:
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetAuthorizationToken",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "eks:DescribeCluster",
        "eks:UpdateClusterConfig",
        "eks:ListClusters",
        "eks:DescribeAddon",
        "eks:CreateAddon",
        "eks:UpdateAddon",
        "sts:AssumeRole",
        "cloudwatch:PutMetricData",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "codebuild:CreateReportGroup",
        "codebuild:CreateReport",
        "codebuild:UpdateReport",
        "codebuild:BatchPutTestCases",
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectVersion"
      ],
      "Resource": "*"
    }
  ]
}
Click "Review policy"
Enter a name for the policy (e.g., CodeBuildMultiRegionDeployPolicy)
Click "Create policy"
Creating Amazon ECR Repositories
Create ECR Repositories in Each Target Region
1.Navigate to Amazon ECR:
oIn the AWS Console, search for "ECR" in the search bar
oClick on "Elastic Container Registry"
2.Create Repository in us-west-2:
oEnsure you're in the us-west-2 region (check top-right corner)
oClick "Repositories" in the left navigation pane
oClick "Create repository"
oFor repository namespace, select "Private"
oEnter my-app-repo-w for Repository name
oLeave default settings for Tag immutability and Scan on push
oClick "Create repository"
3.Create Repository in us-east-1:
oSwitch to the us-east-1 region using the region selector in the top-right corner
oClick "Repositories" in the left navigation pane
oClick "Create repository"
oFor repository namespace, select "Private"
oEnter my-app-repo-e for Repository name
oLeave default settings for Tag immutability and Scan on push
oClick "Create repository"
Creating Amazon EKS Clusters in Multiple Regions
Create an EKS Cluster in us-west-2
1.Navigate to Amazon EKS:
oEnsure you're in the us-west-2 region
oIn the AWS Console, search for "EKS" in the search bar
oClick on "Elastic Kubernetes Service"
2.Create a new cluster:
oClick "Add cluster" → "Create"
oConfigure cluster:
Enter my-cluster-us-west-2 for Name
Select the latest Kubernetes version
Click "Next"
oSpecify networking:
Select your VPC and subnets (or create new ones using the defaults)
Ensure you select subnets in at least two Availability Zones
For Cluster endpoint access, select "Public and private"
Click "Next"
oConfigure logging:
Choose your logging preferences (recommended: enable Control plane logging)
Click "Next"
oReview and create:
Review your settings
Click "Create"
3.Create a node group:
oWhile the cluster is being created (this takes 10-15 minutes), you'll be redirected to the cluster details page
oOnce the cluster status shows as "Active", click on the "Compute" tab
oClick "Add node group"
oConfigure node group:
Enter my-nodes for Name
Select or create an IAM role for the node group
Click "Next"
oSet compute and scaling configuration:
Select instance type: t3.medium
Set minimum size: 2
Set maximum size: 4
Set desired size: 2
Click "Next"
oSpecify networking:
Leave the default settings
Click "Next"
oReview and create:
Review your settings
Click "Create"
Create an EKS Cluster in us-east-1
1.Switch to us-east-1 region:
oUse the region selector in the top-right corner to switch to us-east-1
2.Follow the same steps as above, using these differences:
oCluster name: my-cluster-us-east-1
oNode group name: my-nodes
Installing EKS Add-ons
After both clusters are active, install the required add-ons in each cluster.
For us-west-2 Cluster:
1.Navigate to the EKS Console:
oEnsure you're in the us-west-2 region
oGo to Amazon EKS
oClick on the cluster my-cluster-us-west-2
2.Install Add-ons:
oClick on the "Add-ons" tab
oClick "Get more add-ons"
oInstall each of the following add-ons one by one:
 1. CoreDNS:
oSelect "CoreDNS"
oClick "Next"
oUse the default version
oClick "Next"
oClick "Create"
 2. kube-proxy:
oSelect "kube-proxy"
oClick "Next"
oUse the default version
oClick "Next"
oClick "Create"
 3. Amazon VPC CNI:
oSelect "Amazon VPC CNI"
oClick "Next"
oUse the default version
oClick "Next"
oClick "Create"
 4. AWS Load Balancer Controller:
oSelect "AWS Load Balancer Controller"
oClick "Next"
oUse the default version
oClick "Next"
oClick "Create"
 5. Amazon EFS CSI Driver:
oSelect "Amazon EFS CSI Driver"
oClick "Next"
oUse the default version
oClick "Next"
oClick "Create"
 6. Metrics Server:
oClick "Get more add-ons"
oFind and select "Metrics Server"
oClick "Next"
oUse the default version
oClick "Next"
oClick "Create"
For us-east-1 Cluster:
1.Switch to us-east-1 region:
oUse the region selector to switch to us-east-1
2.Repeat the same add-on installation steps for my-cluster-us-east-1
Preparing Configuration Files
Buildspec.yml
Create a buildspec.yml file with the following content:
version: 0.2
env:
  variables:
    AWS_ACCOUNT_ID: "676206923960"
    AWS_DEFAULT_REGION: "us-west-2"
    IMAGE_REPO_NAME: "my-app-repo"
    IMAGE_REPO_NAME_W: "my-app-repo-w"
    IMAGE_REPO_NAME_E: "my-app-repo-e"
    AWS_DEPLOY_REGIONS_w: "us-west-2"
    AWS_DEPLOY_REGIONS_e: "us-east-1"
phases:
  install:
    runtime-versions:
      docker: latest
    commands:
      - "echo Installing dependencies..."
      - "apt-get update -y"
      - "apt-get install -y apt-transport-https ca-certificates curl"
      - "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -"
      - "add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\""
      - "apt-get update -y"
      - "apt-get install -y docker-ce docker-ce-cli containerd.io"
      - curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.22.6/bin/linux/amd64/aws-iam-authenticator
      - chmod +x ./aws-iam-authenticator
      - mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator
      - aws --version
      - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      - chmod +x kubectl
      - mv kubectl /usr/local/bin/
      - kubectl version --client
  pre_build:
    commands:
      - "echo Logging in to Amazon ECR in all regions..."
      - "for REGION in $AWS_DEPLOY_REGIONS_w $AWS_DEPLOY_REGIONS_e; do echo \"Logging into ECR in $REGION...\"; aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.$REGION.amazonaws.com || echo \"ECR login failed in $REGION\"; done"
  build:
    commands:
      - "echo Building Docker image..."
      - "IMAGE_TAG=$(date +%Y%m%d%H%M%S)"
      - "UNIQUE_LATEST_TAG=latest-${IMAGE_TAG}"
      - "IMAGE_URI=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}"
      - "docker build -t $IMAGE_URI ."
      - "echo Image built: $IMAGE_URI"
  post_build:
    commands:
      - "echo Pushing Docker images to ECR..."
      - "for REGION in $AWS_DEPLOY_REGIONS_w $AWS_DEPLOY_REGIONS_e; do if [ \"$REGION\" = \"us-west-2\" ]; then REPO=\"$IMAGE_REPO_NAME_W\"; elif [ \"$REGION\" = \"us-east-1\" ]; then REPO=\"$IMAGE_REPO_NAME_E\"; else REPO=\"$IMAGE_REPO_NAME\"; fi; echo \"Tagging and pushing image to $REGION ($REPO)...\"; docker tag $IMAGE_URI ${AWS_ACCOUNT_ID}.dkr.ecr.$REGION.amazonaws.com/$REPO:${IMAGE_TAG}; docker tag $IMAGE_URI ${AWS_ACCOUNT_ID}.dkr.ecr.$REGION.amazonaws.com/$REPO:${UNIQUE_LATEST_TAG}; docker push ${AWS_ACCOUNT_ID}.dkr.ecr.$REGION.amazonaws.com/$REPO:${IMAGE_TAG} || echo \"Failed to push tag $IMAGE_TAG in $REGION\"; docker push ${AWS_ACCOUNT_ID}.dkr.ecr.$REGION.amazonaws.com/$REPO:${UNIQUE_LATEST_TAG} || echo \"Failed to push tag $UNIQUE_LATEST_TAG in $REGION\"; done"
      - "echo Creating deployment YAML file..."
      - "mkdir -p kubernetes"
      - "for REGION in $AWS_DEPLOY_REGIONS_w $AWS_DEPLOY_REGIONS_e; do if [ \"$REGION\" = \"us-west-2\" ]; then REPO=\"$IMAGE_REPO_NAME_W\"; elif [ \"$REGION\" = \"us-east-1\" ]; then REPO=\"$IMAGE_REPO_NAME_E\"; else REPO=\"$IMAGE_REPO_NAME\"; fi; echo \"Creating deployment file for $REGION...\"; cat > kubernetes/deployment-$REGION.yaml << EOF"
      - "apiVersion: apps/v1"
      - "kind: Deployment"
      - "metadata:"
      - "  name: my-deployment"
      - "  labels:"
      - "    app: my-app"
      - "spec:"
      - "  replicas: 2"
      - "  selector:"
      - "    matchLabels:"
      - "      app: my-app"
      - "  template:"
      - "    metadata:"
      - "      labels:"
      - "        app: my-app"
      - "    spec:"
      - "      containers:"
      - "        - name: my-container"
      - "          image: ${AWS_ACCOUNT_ID}.dkr.ecr.$REGION.amazonaws.com/$REPO:${UNIQUE_LATEST_TAG}"
      - "          imagePullPolicy: Always"
      - "          ports:"
      - "            - containerPort: 80"
      - "---"
      - "apiVersion: v1"
      - "kind: Service"
      - "metadata:"
      - "  name: my-service"
      - "spec:"
      - "  selector:"
      - "    app: my-app"
      - "  ports:"
      - "    - protocol: TCP"
      - "      port: 80"
      - "      targetPort: 80"
      - "      nodePort: 30080"
      - "  type: NodePort"
      - "EOF"
      - "done"
      - "echo Deploying updated image to Kubernetes..."
      - "for REGION in $AWS_DEPLOY_REGIONS_w $AWS_DEPLOY_REGIONS_e; do if [ \"$REGION\" = \"us-west-2\" ]; then REPO=\"$IMAGE_REPO_NAME_W\"; elif [ \"$REGION\" = \"us-east-1\" ]; then REPO=\"$IMAGE_REPO_NAME_E\"; else REPO=\"$IMAGE_REPO_NAME\"; fi; echo \"Updating EKS cluster in $REGION...\"; aws eks update-kubeconfig --region $REGION --name my-cluster-$REGION --alias my-cluster-$REGION --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/service-role/codebuild-Test-service-role || echo \"EKS config update failed in $REGION\"; echo \"Applying deployment in $REGION...\"; kubectl apply -f kubernetes/deployment-$REGION.yaml --context my-cluster-$REGION || echo \"K8s apply failed in $REGION\"; kubectl rollout status deployment/my-deployment --timeout=90s --context my-cluster-$REGION || echo \"K8s rollout status failed in $REGION\"; done"
      - "echo Writing image definitions file..."
      - "printf '[{\"name\":\"%s\",\"imageUri\":\"%s\"}]' \"$IMAGE_REPO_NAME\" \"$IMAGE_URI\" > imagedefinitions.json"
      - "cat imagedefinitions.json"
artifacts:
  files:
    - imagedefinitions.json
    - kubernetes/*
Kubernetes Deployment File
Create a deployment.yaml file with the following content. This file will be used as a template and dynamically populated by the buildspec:
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
  labels:
    app: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-container
          image: <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/<REPO>:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
  type: NodePort
Creating and Deploying the Pipeline
Create a Pipeline in AWS CodePipeline
1.Open the AWS CodePipeline Console:
oIn the AWS Console, search for "CodePipeline" in the search bar
oClick on "CodePipeline"
2.Create a New Pipeline:
oClick "Create pipeline"
oPipeline settings:
Pipeline name: Enter multi-region-deployment-pipeline
Service role: Select "New service role"
Click "Next"
3.Add the Source Stage:
oSource provider: Choose "GitHub (Version 2)"
oClick "Connect to GitHub"
oFollow the prompts to connect your GitHub account
oRepository: Select "sachinbhirud1998/htmlfile"
oBranch: Select "main"
oDetection options: Choose "GitHub webhooks (recommended)"
oClick "Next"
4.Add the Build Stage:
oBuild provider: Choose "AWS CodeBuild"
oRegion: Select your primary region (e.g., us-west-2)
oProject name:
Click "Create project"
Project configuration:
Project name: Enter multi-region-build-project
Description: (Optional) "Build project for multi-region deployment"
Environment:
Environment image: Select "Managed image"
Operating system: Select "Ubuntu"
Runtime: Select "Standard"
Image: Select the latest version available
Privileged: Check this box (needed for Docker)
Service role: Select "New service role" or use your existing role
Buildspec:
Choose "Use a buildspec file"
Environment variables:
Name: AWS_ACCOUNT_ID, Value: 676206923960
Name: AWS_DEFAULT_REGION, Value: us-west-2
Name: IMAGE_REPO_NAME, Value: my-app-repo
Name: IMAGE_REPO_NAME_W, Value: my-app-repo-w
Name: IMAGE_REPO_NAME_E, Value: my-app-repo-e
Name: AWS_DEPLOY_REGIONS_w, Value: us-west-2
Name: AWS_DEPLOY_REGIONS_e, Value: us-east-1
Click "Continue to CodePipeline"
oClick "Next"
5.Skip Deploy Stage (since deployment is handled by the build stage):
oClick "Skip deploy stage"
6.Review and Create:
oReview all settings and configurations
oClick "Create pipeline"
Verifying the Deployment
After your pipeline runs successfully:
1.Check the Deployment Status in Each Region:
oIn the AWS Console, navigate to EKS
oFor each region (us-west-2 and us-east-1), select the respective cluster
oClick on the "Resources" tab
oClick on "Workloads"
oVerify that "Deployments" shows "my-deployment" with the desired number of replicas
oVerify that "Services" shows "my-service" of type NodePort
2.Access the Application:
oIn the AWS Console, navigate to EC2
oFor each region, locate the EC2 instances associated with your EKS nodes
oNote the public IP address of any node
oOpen a web browser and navigate to http://<node-public-ip>:30080
oVerify that your application is accessible
Troubleshooting Tips
1.Pipeline Failures:
oIn the CodePipeline console, click on the failed pipeline
oIdentify the failed stage and click on "Details"
oFor build stage failures, review the CodeBuild logs
oCheck for:
ECR login issues
Docker build failures
Kubernetes deployment errors
2.EKS Issues:
oIn the EKS console, select your cluster
oCheck the cluster status and health
oReview node group status in the "Compute" tab
oCheck add-on status in the "Add-ons" tab
3.Service Accessibility Issues:
oVerify that the NodePort service is created:
Navigate to EKS → select cluster → Resources → Workloads → Services
Confirm "my-service" is present with type NodePort
oCheck security group settings:
Ensure that port 30080 is allowed in the node security group
Navigate to EC2 → Security Groups → find your node group security group
Edit inbound rules to allow traffic on port 30080 if needed
4.Repository Issues:
oIf code changes are not triggering the pipeline:
Verify GitHub webhook settings
Check that the specified branch (main) has been updated
Manually start the pipeline to rule out trigger issues
