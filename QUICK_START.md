# Quick Start Guide - RDS Replication with AWS SSM

## ✅ What Changed

Your workflow now uses **AWS Systems Manager (SSM)** instead of SSH tunnels - the same approach your team uses for database tests!

---

## 🚀 3 Steps to Get Started

### Step 1: Add GitHub Secrets

Go to: `https://github.com/Yashwardhan-41007/RDS-databasereplication-prototype/settings/secrets/actions`

**Add these 3 secrets:**

1. **`AWS_ACCESS_KEY_ID`** - Your AWS access key
2. **`AWS_SECRET_ACCESS_KEY`** - Your AWS secret key  
3. **`SSM_INSTANCE_ID`** - Value: `i-0af51889228f2d442`

**Note:** Your team likely already has the AWS credentials. Check if they exist first!

---

### Step 2: Verify EC2 Instance

The workflow uses your team's EC2 instance: **`i-0af51889228f2d442`**

**Quick checks:**
```bash
# SSH to the instance
ssh -i buildpiper.pem ubuntu@your-bastion-host

# Verify MySQL client is installed
mysql --version

# Verify SSM agent is running
sudo systemctl status amazon-ssm-agent
```

If MySQL is not installed:
```bash
sudo apt-get update && sudo apt-get install -y mysql-client
```

---

### Step 3: Run the Workflow

1. Go to **Actions** tab on GitHub
2. Click **"RDS Replication"**
3. Click **"Run workflow"**
4. Fill in:
   - Database name
   - Source RDS host (private endpoint is fine!)
   - Source credentials
   - Target RDS host (private endpoint is fine!)
   - Target credentials
5. Click **"Run workflow"**
6. ✅ Done!

---

## 🎯 Key Benefits

- ✅ **No security group changes needed**
- ✅ **No SSH keys to manage**
- ✅ **Works with private RDS**
- ✅ **Same approach your team uses**
- ✅ **IAM-based authentication**

---

## 📚 Need More Details?

- **Full setup guide:** See `SSM_SETUP.md`
- **How it works:** See architecture diagram in `SSM_SETUP.md`
- **Troubleshooting:** See troubleshooting section in `SSM_SETUP.md`

---

## 🔍 How It Works (Simple Version)

```
GitHub Actions
     ↓ (sends command via AWS SSM API)
EC2 Instance (i-0af51889228f2d442)
     ↓ (executes mysqldump)
Source RDS → Target RDS
```

The EC2 instance is already inside your VPC, so it can access private RDS directly!

---

## ⚠️ Common Issues

### "InvalidInstanceId" Error
- Check `SSM_INSTANCE_ID` secret is set to: `i-0af51889228f2d442`

### "AccessDeniedException" Error
- AWS credentials don't have SSM permissions
- Ask your team for credentials with SSM access

### "TargetNotConnected" Error
- SSM agent not running on EC2
- SSH to EC2 and run: `sudo systemctl start amazon-ssm-agent`

---

## 🎉 That's It!

You're using the same infrastructure and approach as your team. No special setup needed!

**Just add the 3 secrets and run the workflow!**
