# AWS SSM Setup Guide for RDS Replication

This workflow uses **AWS Systems Manager (SSM)** to execute database replication commands on an EC2 instance inside your VPC - the same approach your team uses for database connectivity tests!

---

## 🏗️ How It Works

```
GitHub Actions (Cloud)
         │
         │ AWS SSM API
         ▼
AWS Systems Manager
         │
         │ Send commands
         ▼
    EC2 Instance (i-0af51889228f2d442)
    (Inside VPC)
         │
         │ Direct MySQL connection
         ├─► Source RDS (private)
         └─► Target RDS (private)
```

**Key Benefits:**
- ✅ No SSH needed
- ✅ No security group changes
- ✅ Uses AWS IAM for authentication
- ✅ Same approach your team uses
- ✅ Works with private RDS instances

---

## 📋 Prerequisites

### 1. EC2 Instance with SSM Agent
Your team already has this: **`i-0af51889228f2d442`**

**Requirements:**
- ✅ SSM Agent installed (usually pre-installed on Amazon Linux/Ubuntu)
- ✅ IAM role attached with SSM permissions
- ✅ Can access both source and target RDS instances
- ✅ MySQL client installed

### 2. AWS Credentials
You need AWS access keys with SSM permissions.

---

## 🔧 Setup Steps

### Step 1: Get AWS Credentials

**Option A: Use Existing Credentials (Recommended)**
Your team likely already has AWS credentials in GitHub secrets. Check if these exist:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**To check:**
1. Go to your repository on GitHub
2. Settings → Secrets and variables → Actions
3. Look for `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

**If they exist:** ✅ You're done! Skip to Step 3.

**Option B: Create New IAM User**
If credentials don't exist, create a new IAM user:

1. **AWS Console** → **IAM** → **Users** → **Create user**
2. **User name:** `github-actions-rds-replication`
3. **Attach policies:**
   - `AmazonSSMFullAccess` (or create custom policy below)
4. **Create access key** → **Application running outside AWS**
5. **Copy Access Key ID and Secret Access Key**

---

### Step 2: Add Secrets to GitHub

Go to your repository:
```
https://github.com/Yashwardhan-41007/RDS-databasereplication-prototype/settings/secrets/actions
```

**Add these 3 secrets:**

#### Secret 1: AWS_ACCESS_KEY_ID
- **Name:** `AWS_ACCESS_KEY_ID`
- **Value:** Your AWS access key ID (e.g., `AKIAIOSFODNN7EXAMPLE`)

#### Secret 2: AWS_SECRET_ACCESS_KEY
- **Name:** `AWS_SECRET_ACCESS_KEY`
- **Value:** Your AWS secret access key (e.g., `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)

#### Secret 3: SSM_INSTANCE_ID
- **Name:** `SSM_INSTANCE_ID`
- **Value:** `i-0af51889228f2d442` (your team's EC2 instance)

---

### Step 3: Verify EC2 Instance Setup

#### Check SSM Agent Status
SSH to the EC2 instance and verify:

```bash
# Check if SSM agent is running
sudo systemctl status amazon-ssm-agent

# If not running, start it
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
```

#### Check MySQL Client
```bash
# Verify MySQL client is installed
mysql --version

# If not installed
sudo apt-get update
sudo apt-get install -y mysql-client  # Ubuntu/Debian
# OR
sudo yum install -y mysql  # Amazon Linux
```

#### Test RDS Connectivity
```bash
# Test source RDS
mysql -h cars24-qa-mysql8-0-35.cbso2wac2573.ap-south-1.rds.amazonaws.com -u your_user -p

# Test target RDS
mysql -h c2b-qa-mysql.cbso2wac2573.ap-south-1.rds.amazonaws.com -u your_user -p
```

---

### Step 4: Verify IAM Permissions

The EC2 instance needs an IAM role with SSM permissions.

#### Check Current Role:
1. **EC2 Console** → **Instances** → Select `i-0af51889228f2d442`
2. **Security** tab → **IAM Role**
3. Click on the role name

#### Required Permissions:
The role should have these policies:
- `AmazonSSMManagedInstanceCore` (for SSM)
- Or custom policy with:
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource": "*"
      }
    ]
  }
  ```

---

### Step 5: Commit and Push Workflow

```bash
cd /Users/a41007/Documents/rds-replication-automation

git add .github/workflows/rds-replication.yml SSM_SETUP.md
git commit -m "Switch to AWS SSM approach for RDS replication"
git push
```

---

### Step 6: Test the Workflow!

1. **Go to GitHub Actions:**
   ```
   https://github.com/Yashwardhan-41007/RDS-databasereplication-prototype/actions
   ```

2. **Click "RDS Replication" workflow**

3. **Click "Run workflow"**

4. **Fill in the form:**
   - Database name: Your database name
   - Source RDS host: `cars24-qa-mysql8-0-35.cbso2wac2573.ap-south-1.rds.amazonaws.com`
   - Source credentials
   - Target RDS host: `c2b-qa-mysql.cbso2wac2573.ap-south-1.rds.amazonaws.com`
   - Target credentials

5. **Click "Run workflow"** and watch the magic! ✨

---

## 🔍 How Commands Are Executed

### What Happens Behind the Scenes:

1. **GitHub Actions sends SSM command:**
   ```bash
   aws ssm send-command \
     --instance-ids i-0af51889228f2d442 \
     --document-name "AWS-RunShellScript" \
     --parameters "commands=['mysql -h rds-host -u user -p...']"
   ```

2. **SSM Agent on EC2 receives command**

3. **EC2 executes the command:**
   ```bash
   mysqldump -h source-rds ... | mysql -h target-rds ...
   ```

4. **Results sent back to GitHub Actions**

5. **You see the output in GitHub logs**

---

## 🎯 Advantages Over SSH Tunnel

| Feature | SSH Tunnel | AWS SSM |
|---------|------------|---------|
| **Security group changes** | Required | ❌ Not needed |
| **SSH key management** | Required | ❌ Not needed |
| **Authentication** | SSH key | ✅ AWS IAM |
| **Setup complexity** | Medium | ✅ Simple |
| **Team alignment** | Different | ✅ Same as team |
| **Maintenance** | Keys to rotate | ✅ IAM managed |

---

## 🛠️ Troubleshooting

### Error: "An error occurred (InvalidInstanceId)"

**Cause:** Instance ID is wrong or instance doesn't exist

**Fix:**
1. Verify instance ID in AWS Console
2. Update `SSM_INSTANCE_ID` secret with correct value

---

### Error: "TargetNotConnected"

**Cause:** SSM agent not running or instance not registered

**Fix:**
1. SSH to EC2 instance
2. Check SSM agent:
   ```bash
   sudo systemctl status amazon-ssm-agent
   sudo systemctl start amazon-ssm-agent
   ```
3. Check IAM role is attached to instance

---

### Error: "AccessDeniedException"

**Cause:** AWS credentials don't have SSM permissions

**Fix:**
1. Go to IAM → Users → Your user
2. Attach policy: `AmazonSSMFullAccess`
3. Or add custom policy with `ssm:SendCommand` permission

---

### Error: "Command timed out"

**Cause:** Database replication taking too long

**Fix:**
- This is normal for large databases
- The workflow has a 1-hour timeout
- Check SSM command history in AWS Console for status

---

### MySQL Connection Fails on EC2

**Cause:** EC2 can't reach RDS

**Fix:**
1. Check RDS security groups allow EC2
2. Verify RDS endpoints are correct
3. Test manually from EC2:
   ```bash
   mysql -h rds-endpoint -u user -p
   ```

---

## 📊 Monitoring

### View SSM Command History:

1. **AWS Console** → **Systems Manager** → **Run Command**
2. See all commands executed
3. View detailed output and errors

### View GitHub Actions Logs:

1. **GitHub** → **Actions** tab
2. Click on workflow run
3. Expand each step to see detailed logs

---

## 🔐 Security Best Practices

### ✅ What's Secure:
- AWS credentials encrypted in GitHub
- Passwords masked in logs
- IAM-based authentication
- No public SSH exposure
- Commands executed in private VPC

### 💡 Recommendations:
1. **Use least privilege IAM policy** (only SSM permissions needed)
2. **Rotate AWS access keys** regularly
3. **Monitor SSM command history** for unauthorized access
4. **Use read-only RDS users** when possible for source
5. **Enable CloudTrail** to audit SSM API calls

---

## ✅ Verification Checklist

Before running the workflow:

- [ ] AWS credentials added to GitHub secrets
- [ ] SSM instance ID added to GitHub secrets
- [ ] EC2 instance has SSM agent running
- [ ] EC2 instance has IAM role with SSM permissions
- [ ] MySQL client installed on EC2
- [ ] EC2 can connect to both source and target RDS
- [ ] RDS security groups allow EC2
- [ ] Workflow file committed and pushed

---

## 🎉 You're Ready!

This approach is:
- ✅ **Simpler** than SSH tunnels
- ✅ **More secure** (no SSH exposure)
- ✅ **Aligned with your team** (same method they use)
- ✅ **Production-ready**

**Run the workflow and watch it work!** 🚀

---

## 📞 Need Help?

Check the workflow logs for detailed error messages. Most issues are related to:
1. Missing or incorrect AWS credentials
2. SSM agent not running
3. IAM permissions
4. RDS connectivity from EC2

All of these can be verified and fixed using the troubleshooting section above!
