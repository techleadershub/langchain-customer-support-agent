# 🚀 AWS Deployment Guide

Complete step-by-step guide to deploy the Customer Support Agent to AWS App Runner.

---

## 📋 Prerequisites Checklist

Before deploying, ensure you have:

- [ ] **AWS Account** (with billing enabled)
- [ ] **AWS CLI installed** on your machine
- [ ] **AWS credentials configured** (`aws configure`)
- [ ] **Docker Desktop running**
- [ ] **`.env` file** with required credentials
- [ ] **IAM permissions** for ECR and App Runner

---

## 🔧 Step 1: Install AWS CLI

### Windows (PowerShell):
```powershell
# Option 1: Download installer
# https://aws.amazon.com/cli/

# Option 2: Using winget
winget install Amazon.AWSCLI

# Verify installation
aws --version
```

### macOS:
```bash
brew install awscli
```

### Linux:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

---

## 🔐 Step 2: Configure AWS Credentials

### 2.1 Get AWS Access Keys

1. **Login to AWS Console**: https://console.aws.amazon.com
2. **Go to IAM**: Services → IAM → Users
3. **Create/Select User**:
   - Click "Create User" or select existing user
   - Username: `customer-support-deployer`
4. **Attach Policies**:
   - `AmazonEC2ContainerRegistryFullAccess` (for ECR)
   - `AWSAppRunnerFullAccess` (for App Runner)
   - `CloudWatchLogsFullAccess` (for logs)
5. **Create Access Key**:
   - Security credentials tab → Create access key
   - Choose "Command Line Interface (CLI)"
   - **Save Access Key ID and Secret Access Key** (you won't see it again!)

### 2.2 Configure AWS CLI

```powershell
aws configure
```

Enter the following when prompted:

```
AWS Access Key ID: [Your Access Key ID]
AWS Secret Access Key: [Your Secret Access Key]
Default region name: ap-south-1
Default output format: json
```

### 2.3 Verify Configuration

```powershell
# Test AWS connection
aws sts get-caller-identity

# Should output:
# {
#     "UserId": "...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-username"
# }
```

If you see your account details, you're ready! ✅

---

## 📝 Step 3: Prepare Environment Variables

### 3.1 Create `.env` File

Copy the example file:
```powershell
copy env.example .env
```

### 3.2 Edit `.env` File

Open `.env` and add your credentials:

```env
# Required: OpenAI API Key
OPENAI_API_KEY=sk-proj-your-key-here

# Database (choose ONE method):

# Option 1: Direct PostgreSQL (recommended)
DATABASE_URL=postgresql://postgres:password@db.project.supabase.co:5432/postgres

# Option 2: Supabase Client (alternative)
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_KEY=your-anon-key-here

# AWS Region (optional - defaults to ap-south-1)
AWS_REGION=ap-south-1
```

**Important Notes:**
- `OPENAI_API_KEY` is **required**
- Database credentials are **optional** (app works without database)
- Never commit `.env` to git!

---

## 🐳 Step 4: Verify Docker

### 4.1 Check Docker is Running

```powershell
# Check Docker version
docker --version

# Check Docker is running
docker ps
```

If Docker Desktop is not running:
1. Open Docker Desktop
2. Wait for it to start (green icon in system tray)
3. Run `docker ps` again

---

## 🚀 Step 5: Deploy to AWS

### 5.1 Run Deployment Script

```powershell
# Deploy to AWS App Runner (recommended)
.\deploy.ps1 app-runner
```

### 5.2 What Happens During Deployment

The script automatically:

1. ✅ **Validates** `.env` file exists
2. ✅ **Builds** Docker image locally
3. ✅ **Creates** ECR repository (if doesn't exist)
4. ✅ **Logs in** to AWS ECR
5. ✅ **Tags** Docker image
6. ✅ **Pushes** image to ECR
7. ✅ **Creates/Updates** App Runner service
8. ✅ **Injects** environment variables from `.env`
9. ✅ **Returns** service URL

### 5.3 Expected Output

```
🚀 Deploying Customer Support App to AWS
=========================================
Region: ap-south-1
Deploy Method: app-runner

Account: 123456789012
✅ Loaded environment variables:
   - OPENAI_API_KEY: ***
   - DATABASE_URL: postgresql://*** (direct PostgreSQL connection)

📦 Step 1: Building Docker image...
✅ Docker image built

📦 Step 2: Setting up ECR repository...
✅ ECR repository created

🔐 Step 3: Logging into ECR...
✅ Logged into ECR

⬆️  Step 4: Pushing image to ECR...
✅ Image pushed to ECR

🚀 Step 5: Deploying to app-runner...
✅ App Runner service created!

=========================================
🎉 Deployment Complete!
=========================================
Service URL: https://xyz123.ap-south-1.awsapprunner.com
Service ARN: arn:aws:apprunner:ap-south-1:123456789012:service/...
```

---

## ✅ Step 6: Test Deployment

### 6.1 Access Your App

1. **Copy the Service URL** from deployment output
2. **Open in browser**: `https://xyz123.ap-south-1.awsapprunner.com`
3. **Wait 1-2 minutes** for App Runner to start (first deployment takes longer)

### 6.2 Test Functionality

1. **Submit a test ticket**:
   - Subject: "Test Order Issue"
   - Body: "Order ORD123 is broken, need refund"
2. **Click "Classify & Process Ticket"**
3. **Verify**:
   - ✅ Category is classified (refund/technical/billing/general)
   - ✅ Draft response is generated
   - ✅ Refund status shown (if category is refund)

---

## 📊 Step 7: Monitor & Manage

### 7.1 View Service Status

```powershell
# Get service ARN (from deployment output)
$SERVICE_ARN = "arn:aws:apprunner:ap-south-1:123456789012:service/customer-support-app/..."

# View service details
aws apprunner describe-service --service-arn $SERVICE_ARN --region ap-south-1
```

### 7.2 View Logs

**Option 1: AWS Console**
1. Go to: https://console.aws.amazon.com/apprunner
2. Click on your service name
3. Click "Logs" tab
4. View real-time logs

**Option 2: AWS CLI**
```powershell
# View recent logs
aws logs tail /aws/apprunner/customer-support-app --follow --region ap-south-1
```

### 7.3 Update Deployment

After making code changes:

```powershell
# Rebuild and redeploy
.\deploy.ps1 app-runner
```

The script will:
- Build new Docker image
- Push to ECR
- Trigger App Runner update
- Keep same service URL

---

## 🔍 Troubleshooting

### Issue: "AWS CLI not configured"

**Solution:**
```powershell
aws configure
# Enter your Access Key ID, Secret Access Key, Region, Output format
```

### Issue: "Access Denied" errors

**Solution:**
1. Check IAM user has required policies:
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AWSAppRunnerFullAccess`
   - `CloudWatchLogsFullAccess`
2. Verify Access Key is active
3. Check region matches (`ap-south-1`)

### Issue: "ECR login failed"

**Solution:**
```powershell
# Manually login to ECR
$AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com
```

### Issue: "Service not accessible"

**Solution:**
1. Wait 2-3 minutes for App Runner to start
2. Check service status in AWS Console
3. Verify environment variables are set:
   ```powershell
   aws apprunner describe-service --service-arn $SERVICE_ARN --region ap-south-1 --query 'Service.InstanceConfiguration.EnvironmentVariables'
   ```

### Issue: "Docker build failed"

**Solution:**
1. Ensure Docker Desktop is running
2. Check Dockerfile syntax
3. Verify all files are present:
   ```powershell
   Test-Path Dockerfile
   Test-Path pyproject.toml
   Test-Path app_langchain.py
   Test-Path config.py
   ```

### Issue: "Environment variables not working"

**Solution:**
1. Verify `.env` file format (no spaces around `=`)
   ```env
   # Correct
   OPENAI_API_KEY=sk-proj-xxx
   
   # Wrong
   OPENAI_API_KEY = sk-proj-xxx
   ```
2. Check variables are in `.env` file
3. Redeploy: `.\deploy.ps1 app-runner`

---

## 💰 Cost Estimation

### AWS App Runner Pricing (Mumbai Region)

- **Compute**: ~$0.007 per vCPU-hour
- **Memory**: ~$0.0008 per GB-hour
- **Data Transfer**: ~$0.20 per GB

### Estimated Monthly Cost

| Usage Level | vCPU | Memory | Estimated Cost |
|-------------|------|--------|----------------|
| **Light** (1-2 hours/day) | 1 | 2 GB | $5-10/month |
| **Medium** (4-6 hours/day) | 1 | 2 GB | $15-25/month |
| **Heavy** (24/7) | 1 | 2 GB | $50-80/month |

**Note:** First 100 GB data transfer per month is free.

---

## 🔄 Update Deployment

### After Code Changes

1. **Make your changes** to code
2. **Test locally**:
   ```powershell
   docker-compose up
   ```
3. **Redeploy**:
   ```powershell
   .\deploy.ps1 app-runner
   ```

### Update Environment Variables

1. **Edit `.env` file** with new values
2. **Redeploy**:
   ```powershell
   .\deploy.ps1 app-runner
   ```
3. App Runner will automatically update with new environment variables

---

## 🗑️ Delete Deployment

### Remove App Runner Service

```powershell
# Get service ARN
$SERVICE_ARN = "arn:aws:apprunner:ap-south-1:123456789012:service/customer-support-app/..."

# Delete service
aws apprunner delete-service --service-arn $SERVICE_ARN --region ap-south-1
```

### Remove ECR Repository

```powershell
# Delete ECR repository
aws ecr delete-repository --repository-name customer-support-app --region ap-south-1 --force
```

---

## 📚 Additional Resources

- **AWS App Runner Docs**: https://docs.aws.amazon.com/apprunner/
- **AWS CLI Docs**: https://docs.aws.amazon.com/cli/
- **Docker Docs**: https://docs.docker.com/
- **Project README**: See `README.md` for local development

---

## ✅ Quick Reference

### One-Line Deployment
```powershell
.\deploy.ps1 app-runner
```

### Check Service Status
```powershell
aws apprunner list-services --region ap-south-1
```

### View Logs
```powershell
# In AWS Console: App Runner → Your Service → Logs
```

### Update After Code Changes
```powershell
.\deploy.ps1 app-runner
```

---

**🎉 That's it! Your app is now deployed to AWS App Runner.**

For local development, see `README.md`.

