# Quick Start Guide - RDS Replication with AWS SSM

## ✅ What Changed

Your workflow now uses **AWS Systems Manager (SSM)** instead of SSH tunnels - the same approach your team uses for database tests!

---

## 🚀 2 Steps to Get Started

### Step 1: Set Up IAM Role & Add GitHub Secrets

**Your company requires IAM roles (no access keys) - this is more secure!** ✅

#### Option A: Ask Your AWS Admin (Easiest)
Ask your AWS admin to:
1. Create an IAM role for GitHub Actions with SSM permissions
2. Give you the **Role ARN** (looks like: `arn:aws:iam::123456789012:role/RoleName`)

Then add these 2 secrets to GitHub:
- Go to: `https://github.com/Yashwardhan-41007/RDS-databasereplication-prototype/settings/secrets/actions`
- **`AWS_ROLE_ARN`** - The role ARN from your admin
- **`SSM_INSTANCE_ID`** - Value: `i-0af51889228f2d442`

#### Option B: Set It Up Yourself
Follow the detailed guide: **`IAM_ROLE_SETUP.md`**

It takes ~10 minutes and includes:
- Creating OIDC provider (one-time setup)
- Creating IAM role with SSM permissions
- Trust policy configuration

---

### Step 2: Run the Workflow

1. Go to **Actions** tab on GitHub
2. Click **"RDS Replication"**
3. Click **"Run workflow"**
4. Fill in database details
5. ✅ Done!

**Optional: Verify EC2 Instance First**

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

## 🎯 Key Benefits

- ✅ **No security group changes needed**
- ✅ **No SSH keys to manage**
- ✅ **No AWS access keys** (uses IAM roles with OIDC)
- ✅ **Works with private RDS**
- ✅ **Same approach your team uses**
- ✅ **Temporary credentials only** (auto-expire)

---

## 📚 Need More Details?

- **IAM role setup:** See `IAM_ROLE_SETUP.md` (for OIDC authentication)
- **SSM setup guide:** See `SSM_SETUP.md`
- **How it works:** See architecture diagrams in the guides
- **Troubleshooting:** See troubleshooting sections in the guides

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
