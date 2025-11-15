# AWS Deployment Script for Customer Support App (Windows PowerShell)
# Usage: .\deploy.ps1 [app-runner|ecs|ec2]

param(
    [string]$DeployMethod = "app-runner"
)

# Configuration
$APP_NAME = "customer-support-app"
$AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "ap-south-1" }

Write-Host "🚀 Deploying Customer Support App to AWS" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Region: $AWS_REGION"
Write-Host "Deploy Method: $DeployMethod"
Write-Host ""

# Get AWS Account ID
try {
    $AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
    Write-Host "Account: $AWS_ACCOUNT_ID"
} catch {
    Write-Host "❌ Error: AWS CLI not configured or not installed" -ForegroundColor Red
    Write-Host "Please run: aws configure" -ForegroundColor Yellow
    exit 1
}

$ECR_REPO = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$APP_NAME"

# Check if .env exists
if (-Not (Test-Path ".env")) {
    Write-Host "❌ Error: .env file not found" -ForegroundColor Red
    Write-Host "Create .env with: OPENAI_API_KEY=your-key" -ForegroundColor Yellow
    exit 1
}

# Load environment variables from .env
$envVars = @{}
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.+)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $envVars[$key] = $value
        Set-Item -Path "env:$key" -Value $value
    }
}

# Validate required variables
if (-Not $envVars['OPENAI_API_KEY']) {
    Write-Host "❌ Error: OPENAI_API_KEY not found in .env file" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Loaded environment variables:" -ForegroundColor Green
Write-Host "   - OPENAI_API_KEY: ***" -ForegroundColor Gray
if ($envVars['SUPABASE_URL']) {
    Write-Host "   - SUPABASE_URL: $($envVars['SUPABASE_URL'].Substring(0, [Math]::Min(30, $envVars['SUPABASE_URL'].Length)))..." -ForegroundColor Gray
    Write-Host "   - SUPABASE_KEY: ***" -ForegroundColor Gray
} elseif ($envVars['DATABASE_URL']) {
    Write-Host "   - DATABASE_URL: postgresql://*** (direct PostgreSQL connection)" -ForegroundColor Gray
} else {
    Write-Host "   - Database: Not configured (app will work without it)" -ForegroundColor Yellow
}

# Step 1: Build Docker image
Write-Host ""
Write-Host "📦 Step 1: Building Docker image..." -ForegroundColor Cyan
docker build -t ${APP_NAME}:latest .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Docker image built" -ForegroundColor Green

# Step 2: Create ECR repository if it doesn't exist
Write-Host ""
Write-Host "📦 Step 2: Setting up ECR repository..." -ForegroundColor Cyan
$repoExists = aws ecr describe-repositories --repository-names $APP_NAME --region $AWS_REGION 2>$null
if (-Not $repoExists) {
    aws ecr create-repository --repository-name $APP_NAME --region $AWS_REGION | Out-Null
    Write-Host "✅ ECR repository created" -ForegroundColor Green
} else {
    Write-Host "✅ ECR repository exists" -ForegroundColor Green
}

# Step 3: Login to ECR
Write-Host ""
Write-Host "🔐 Step 3: Logging into ECR..." -ForegroundColor Cyan
$loginCommand = aws ecr get-login-password --region $AWS_REGION
$loginCommand | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ECR login failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Logged into ECR" -ForegroundColor Green

# Step 4: Tag and push image
Write-Host ""
Write-Host "⬆️  Step 4: Pushing image to ECR..." -ForegroundColor Cyan
docker tag ${APP_NAME}:latest ${ECR_REPO}:latest
docker push ${ECR_REPO}:latest
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Image push failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Image pushed to ECR" -ForegroundColor Green

# Step 5: Deploy based on method
Write-Host ""
Write-Host "🚀 Step 5: Deploying to $DeployMethod..." -ForegroundColor Cyan

switch ($DeployMethod) {
    "app-runner" {
        # Check if service exists
        $serviceArn = aws apprunner list-services --region $AWS_REGION --query "ServiceSummaryList[?ServiceName=='$APP_NAME'].ServiceArn" --output text
        
        if ([string]::IsNullOrEmpty($serviceArn)) {
            Write-Host "Creating new App Runner service..." -ForegroundColor Yellow
            
            # Build environment variables JSON
            $envVariables = @{
                OPENAI_API_KEY = $envVars['OPENAI_API_KEY']
            }
            
            # Add Supabase variables if present (preferred method)
            if ($envVars['SUPABASE_URL']) {
                $envVariables['SUPABASE_URL'] = $envVars['SUPABASE_URL']
            }
            if ($envVars['SUPABASE_KEY']) {
                $envVariables['SUPABASE_KEY'] = $envVars['SUPABASE_KEY']
            }
            
            # Add DATABASE_URL if present (alternative method - direct PostgreSQL)
            if ($envVars['DATABASE_URL']) {
                $envVariables['DATABASE_URL'] = $envVars['DATABASE_URL']
            }
            
            $envVarsJson = ($envVariables.GetEnumerator() | ForEach-Object { "$($_.Key)='$($_.Value)'" }) -join ','
            
            # Create service
            $createResult = aws apprunner create-service `
                --service-name $APP_NAME `
                --region $AWS_REGION `
                --source-configuration "ImageRepository={ImageIdentifier=$ECR_REPO`:latest,ImageRepositoryType=ECR,ImageConfiguration={Port='8501',RuntimeEnvironmentVariables={$envVarsJson}}},AutoDeploymentsEnabled=true" `
                --instance-configuration Cpu=1024,Memory=2048 `
                --output json
            
            $serviceArn = ($createResult | ConvertFrom-Json).Service.ServiceArn
            Write-Host "✅ App Runner service created!" -ForegroundColor Green
        } else {
            Write-Host "Updating existing App Runner service..." -ForegroundColor Yellow
            
            # Build environment variables for update
            $envVariables = @{
                OPENAI_API_KEY = $envVars['OPENAI_API_KEY']
            }
            
            # Add Supabase variables if present
            if ($envVars['SUPABASE_URL']) {
                $envVariables['SUPABASE_URL'] = $envVars['SUPABASE_URL']
            }
            if ($envVars['SUPABASE_KEY']) {
                $envVariables['SUPABASE_KEY'] = $envVars['SUPABASE_KEY']
            }
            
            # Add DATABASE_URL if present
            if ($envVars['DATABASE_URL']) {
                $envVariables['DATABASE_URL'] = $envVars['DATABASE_URL']
            }
            
            # Convert to JSON format for AWS CLI
            $envVarsJson = ($envVariables.GetEnumerator() | ForEach-Object { "$($_.Key)='$($_.Value)'" }) -join ','
            
            # Update service configuration with new environment variables and image
            aws apprunner update-service `
                --service-arn $serviceArn `
                --region $AWS_REGION `
                --source-configuration "ImageRepository={ImageIdentifier=$ECR_REPO`:latest,ImageRepositoryType=ECR,ImageConfiguration={Port='8501',RuntimeEnvironmentVariables={$envVarsJson}}},AutoDeploymentsEnabled=true" `
                --output json | Out-Null
            
            # Start deployment with updated configuration
            aws apprunner start-deployment --service-arn $serviceArn --region $AWS_REGION | Out-Null
            Write-Host "✅ App Runner service updated with new image and environment variables!" -ForegroundColor Green
        }
        
        # Wait a moment and get service URL
        Start-Sleep -Seconds 10
        $serviceInfo = aws apprunner describe-service --service-arn $serviceArn --region $AWS_REGION | ConvertFrom-Json
        $serviceUrl = $serviceInfo.Service.ServiceUrl
        
        Write-Host ""
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host "Service URL: https://$serviceUrl" -ForegroundColor Cyan
        Write-Host "Service ARN: $serviceArn" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Monitor logs with:" -ForegroundColor Yellow
        Write-Host "aws apprunner describe-service --service-arn $serviceArn --region $AWS_REGION" -ForegroundColor Gray
    }
    
    "ecs" {
        Write-Host "🚀 Step 5: Deploying to AWS ECS Fargate..." -ForegroundColor Cyan
        Write-Host "⚠️  This requires additional VPC/subnet/security group configuration" -ForegroundColor Yellow
        Write-Host "Please configure manually or use AWS Console" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Image ready at: $ECR_REPO`:latest" -ForegroundColor Cyan
    }
    
    "ec2" {
        Write-Host "🚀 Step 5: Deploying to AWS EC2..." -ForegroundColor Cyan
        Write-Host "⚠️  This requires manual EC2 instance setup" -ForegroundColor Yellow
        Write-Host "Please follow these steps:" -ForegroundColor Yellow
        Write-Host "1. Launch EC2 instance (Ubuntu 22.04)" -ForegroundColor Gray
        Write-Host "2. SSH into instance" -ForegroundColor Gray
        Write-Host "3. Install Docker" -ForegroundColor Gray
        Write-Host "4. Pull image: docker pull $ECR_REPO`:latest" -ForegroundColor Gray
        Write-Host "5. Run: docker run -p 8501:8501 -e OPENAI_API_KEY=your-key $ECR_REPO`:latest" -ForegroundColor Gray
    }
    
    default {
        Write-Host "❌ Invalid deployment method: $DeployMethod" -ForegroundColor Red
        Write-Host "Usage: .\deploy.ps1 [app-runner|ecs|ec2]" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "✨ Deployment script completed!" -ForegroundColor Green

