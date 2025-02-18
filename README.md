## Cross-Region Deployable Pipeline Creation Guide

### Introduction
This document provides comprehensive instructions for creating an automated pipeline using AWS CodeBuild and CodePipeline. The pipeline builds a Docker image from a GitHub repository (https://github.com/sachinbhirud1998/htmlfile.git), pushes it to Amazon ECR, and deploys it to Amazon EKS clusters in multiple AWS regions—all from a single branch. The configuration includes proper IAM roles, cross-region deployment steps, and essential EKS add-ons.

---

## Table of Contents
1. Getting Started in the AWS Console
2. Installing Required Tools
3. Configuring IAM Roles and Policies
4. Creating Amazon ECR Repositories
5. Creating Amazon EKS Clusters in Multiple Regions
6. Installing EKS Add-ons
7. Preparing Configuration Files
8. Creating and Deploying the Pipeline
9. Verifying the Deployment
10. Troubleshooting Tips

---

## Getting Started in the AWS Console
1. **Log in to the AWS Management Console:**
   - Open your web browser and navigate to [AWS Console](https://console.aws.amazon.com/)
   - Enter your credentials to access your AWS account
2. **Set your default region:**
   - In the top right corner of the console, select your preferred region (e.g., `us-west-2`)

---

## Installing Required Tools
Ensure the following tools are installed on your local machine if you need to perform administrative tasks outside the console:
- **AWS CLI**: [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- **kubectl**: [Installation Guide](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

---

## Configuring IAM Roles and Policies
### Create a CodeBuild Service Role
1. **Navigate to the IAM Console:**
   - Click on "Services" in the AWS Console
   - Select "IAM" under the "Security, Identity, & Compliance" section
2. **Create a New Role:**
   - Click "Roles" in the left navigation pane
   - Click "Create role"
   - Select "AWS service" as the trusted entity type
   - Choose "CodeBuild" from the use case list
   - Click "Next: Permissions"
3. **Attach Policies:**
   - Attach `AmazonEC2ContainerRegistryPowerUser`
   - Attach `AmazonEKSClusterPolicy`
   - Click "Next: Review"
   - Enter a role name (e.g., `CodeBuildServiceRole-MultiRegion`)
   - Click "Create role"
4. **Add an Inline Policy:**
   - Open the created role, go to "Permissions" > "Add inline policy"
   - Select "JSON" tab and add the following:
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
   - Click "Review policy"
   - Enter a name (e.g., `CodeBuildMultiRegionDeployPolicy`)
   - Click "Create policy"

---

## Creating Amazon ECR Repositories
### Create ECR Repositories in Each Target Region
1. **Navigate to Amazon ECR:**
   - In the AWS Console, search for "ECR"
   - Click "Elastic Container Registry"
2. **Create Repository in `us-west-2`:**
   - Ensure you're in `us-west-2`
   - Click "Repositories" > "Create repository"
   - Enter `my-app-repo-w` for the repository name
   - Click "Create repository"
3. **Create Repository in `us-east-1`:**
   - Switch to `us-east-1` and repeat the above steps with repository name `my-app-repo-e`

---

## Creating Amazon EKS Clusters in Multiple Regions
### Create an EKS Cluster in `us-west-2`
1. **Navigate to Amazon EKS:**
   - Ensure you're in `us-west-2`
   - Search for "EKS" and select "Elastic Kubernetes Service"
2. **Create a new cluster:**
   - Click "Add cluster" > "Create"
   - Name: `my-cluster-us-west-2`
   - Select latest Kubernetes version
   - Configure networking, logging, and review settings
   - Click "Create"
3. **Create a Node Group:**
   - Once the cluster is active, go to "Compute" > "Add node group"
   - Name: `my-nodes`
   - Instance type: `t3.medium`, Min size: `2`, Max size: `4`, Desired size: `2`
   - Click "Create"

### Create an EKS Cluster in `us-east-1`
- Follow the same steps as above with name `my-cluster-us-east-1`

---

## Installing EKS Add-ons
- Install the following add-ons in each cluster:
  - CoreDNS
  - kube-proxy
  - Amazon VPC CNI
  - AWS Load Balancer Controller
  - Amazon EFS CSI Driver
  - Metrics Server

---

## Preparing Configuration Files
### `buildspec.yml`
- Contains commands for building, tagging, and pushing Docker images to ECR.
- Defines deployment files dynamically.
- Uses `kubectl` to apply Kubernetes manifests to EKS clusters.

### `deployment.yaml`
- Defines Kubernetes deployment and service specifications.

---

## Creating and Deploying the Pipeline
### Create a Pipeline in AWS CodePipeline
1. **Open CodePipeline Console:**
   - Search for "CodePipeline" and select it
2. **Create a New Pipeline:**
   - Name: `multi-region-deployment-pipeline`
   - Service role: "New service role"
3. **Add Source Stage:**
   - Provider: "GitHub"
   - Repository: `sachinbhirud1998/htmlfile`
   - Branch: `main`
4. **Add Build Stage:**
   - Provider: "AWS CodeBuild"
   - Region: `us-west-2`
   - Project name: `multi-region-build-project`

---

## Verifying the Deployment
- Use `kubectl get pods --all-namespaces` to verify running pods.
- Check services with `kubectl get svc`.

---

## Troubleshooting Tips
- Ensure IAM roles have correct permissions.
- Verify ECR login is successful.
- Check CodeBuild logs for errors.
- Use `kubectl logs` to debug pod issues.

---

This guide enables seamless multi-region deployment using AWS services, ensuring scalability and redundancy.

