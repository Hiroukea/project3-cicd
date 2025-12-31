Project 
One-Click Deployment Automation (EC2 + Serverless)

Overview
This project demonstrates a one-click deployment system built on AWS that supports both EC2-based applications and serverless Lambda APIs.  
The goal is to show real-world deployment automation without relying on paid CI/CD tools, using AWS-native services and scripting instead.

The solution supports:
- Automated EC2 deployments via S3 + AWS Systems Manager (SSM)
- Serverless API deployments using AWS SAM
- Versioned releases with rollback capability
- Fully script-driven execution from Windows PowerShell
- 
Architecture
EC2 Deployment Path
1. Application files are packaged into a versioned ZIP release
2. Release is uploaded to Amazon S3
3. PowerShell script triggers AWS SSM Run Command
4. EC2 instance pulls the release from S3
5. NGINX is updated and restarted automatically
6. Deployment is validated via health check

 Serverless Deployment Path
1. AWS SAM builds and packages the Lambda function
2. CloudFormation deploys the stack
3. API Gateway exposes a public endpoint
4. Deployment output returns the live API URL

 Tech Stack
- AWS EC2
- AWS S3
- AWS Systems Manager (SSM)
- AWS Lambda
- API Gateway
- AWS SAM
- CloudFormation
- PowerShell
- Bash
- NGINX

