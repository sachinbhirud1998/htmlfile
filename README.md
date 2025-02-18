# Cross-Region Deployable Pipeline

A comprehensive guide for building an automated CI/CD pipeline that deploys to multiple AWS regions.

## Overview

This project creates an automated pipeline using AWS CodeBuild and CodePipeline. The pipeline builds a Docker image from this repository, pushes it to Amazon ECR, and deploys it to Amazon EKS clusters in multiple AWS regions—all from a single branch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Infrastructure Setup](#aws-infrastructure-setup)
3. [IAM Roles and Policies](#iam-roles-and-policies)
4. [Amazon ECR Repository Setup](#amazon-ecr-repository-setup)
5. [Amazon EKS Cluster Setup](#amazon-eks-cluster-setup)
6. [EKS Add-ons Installation](#eks-add-ons-installation)
7. [Configuration Files](#configuration-files)
8. [Pipeline Deployment](#pipeline-deployment)
9. [Verification](#verification)
10. [Troubleshooting](#troubleshooting)

## Prerequisites

Ensure you have the following:

1. An AWS account with appropriate permissions
2. A GitHub account with this repository forked or cloned
3. The following tools installed locally (optional for AWS Console operations):
   - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
   - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## AWS Infrastructure Setup

Log in to the AWS Management Console at https://console.aws.amazon.com/ and set your default region (e.g., `us-west-2`).

## IAM Roles and Policies

Create a CodeBuild service role with the necessary permissions:

1. Navigate to IAM and create a new role for CodeBuild
2. Attach the following policies:
   - `AmazonEC2ContainerRegistryPowerUser`
   - `AmazonEKSClusterPolicy`
3. Add an inline policy with the following permissions:

```json
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
```

## Amazon ECR Repository Setup

Create ECR repositories in each target region:

### us-west-2 Region
1. Navigate to ECR in the us-west-2 region
2. Create a private repository named `my-app-repo-w`

### us-east-1 Region
1. Switch to the us-east-1 region
2. Create a private repository named `my-app-repo-e`

## Amazon EKS Cluster Setup

### us-west-2 Cluster
1. Navigate to EKS in the us-west-2 region
2. Create a new cluster named `my-cluster-us-west-2`
3. Configure networking with public and private endpoints
4. Create a node group with:
   - Name: `my-nodes`
   - Instance type: `t3.medium`
   - Min size: 2, Max size: 4, Desired size: 2

### us-east-1 Cluster
1. Switch to the us-east-1 region
2. Create a new cluster named `my-cluster-us-east-1`
3. Configure networking with public and private endpoints
4. Create a node group with the same settings as above

## EKS Add-ons Installation

Install the following add-ons on each cluster (us-west-2 and us-east-1):

1. CoreDNS
2. kube-proxy
3. Amazon VPC CNI
4. AWS Load Balancer Controller
5. Amazon EFS CSI Driver
6. Metrics Server

## Configuration Files

### buildspec.yml

Create a `buildspec.yml` file in your repository:

```yaml
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
```

### Kubernetes Deployment File Template

Create a `deployment.yaml` template:

```yaml
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
```

## Pipeline Deployment

Create a pipeline in AWS CodePipeline:

1. Open the CodePipeline console and create a new pipeline
2. Name: `multi-region-deployment-pipeline`
3. Source Stage:
   - Provider: GitHub (Version 2)
   - Repository: `sachinbhirud1998/htmlfile`
   - Branch: `main`
   - Detection: GitHub webhooks
4. Build Stage:
   - Provider: AWS CodeBuild
   - Region: `us-west-2`
   - Project name: `multi-region-build-project`
   - Environment:
     - Ubuntu, Standard runtime
     - Managed image (latest version)
     - Privileged mode: checked
   - Buildspec: Use a buildspec file
   - Environment variables:
     - `AWS_ACCOUNT_ID`: `676206923960`
     - `AWS_DEFAULT_REGION`: `us-west-2`
     - `IMAGE_REPO_NAME`: `my-app-repo`
     - `IMAGE_REPO_NAME_W`: `my-app-repo-w`
     - `IMAGE_REPO_NAME_E`: `my-app-repo-e`
     - `AWS_DEPLOY_REGIONS_w`: `us-west-2`
     - `AWS_DEPLOY_REGIONS_e`: `us-east-1`
5. Skip the Deploy Stage (handled by the build stage)
6. Review and create the pipeline

## Verification

After your pipeline runs successfully:

1. Check the deployment status in each region:
   - Navigate to EKS in each region
   - Verify that deployments and services are running
2. Access the application:
   - Get the public IP of an EKS node
   - Open `http://<node-public-ip>:30080` in a browser
   - Verify that your application is accessible

## Troubleshooting

### Pipeline Failures
- In CodePipeline, check the failed stage details
- Review CodeBuild logs for specific errors
- Common issues:
  - ECR login issues
  - Docker build failures
  - Kubernetes deployment errors

### EKS Issues
- Check cluster status and health
- Review node group status
- Verify add-on status

### Service Accessibility Issues
- Confirm NodePort service creation
- Check that port 30080 is allowed in node security groups

### Repository Issues
- Verify GitHub webhook settings
- Check branch updates
- Try manually starting the pipeline
