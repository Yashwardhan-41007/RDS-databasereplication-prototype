# IAM Role Setup for GitHub Actions (OIDC)

This guide shows how to set up an IAM role that GitHub Actions can assume using OpenID Connect (OIDC) - **no access keys needed!**

This is the **most secure** approach and follows AWS best practices.

---

## 🔐 Why IAM Roles > Access Keys

| Feature | Access Keys | IAM Roles (OIDC) |
|---------|-------------|------------------|
| **Security** | ⚠️ Long-lived credentials | ✅ Temporary credentials |
| **Rotation** | ❌ Manual rotation needed | ✅ Auto-rotated |
| **Exposure risk** | ⚠️ Can be leaked | ✅ Never leaves AWS |
| **Audit** | ⚠️ Hard to track | ✅ CloudTrail logs |
| **Best practice** | ❌ Not recommended | ✅ AWS recommended |

---

## 🏗️ Architecture

```
GitHub Actions
     │
     │ OIDC Token
     ▼
AWS STS (Assume Role)
     │
     │ Temporary Credentials
     ▼
IAM Role (with SSM permissions)
     │
     │ Execute SSM commands
     ▼
EC2 Instance → RDS
```

---

## 📋 Setup Steps

### Step 1: Create OIDC Identity Provider in AWS

This is a **one-time setup** for your AWS account. Your company may have already done this!

**Check if it exists:**
1. AWS Console → **IAM** → **Identity providers**
2. Look for provider with URL: `token.actions.githubusercontent.com`

**If it exists:** ✅ Skip to Step 2

**If it doesn't exist:**
1. Go to **IAM** → **Identity providers** → **Add provider**
2. **Provider type:** OpenID Connect
3. **Provider URL:** `https://token.actions.githubusercontent.com`
4. Click **Get thumbprint**
5. **Audience:** `sts.amazonaws.com`
6. Click **Add provider**

---

### Step 2: Create IAM Role for GitHub Actions

#### 2.1: Create the Role

1. **IAM** → **Roles** → **Create role**
2. **Trusted entity type:** Web identity
3. **Identity provider:** `token.actions.githubusercontent.com`
4. **Audience:** `sts.amazonaws.com`
5. Click **Next**

#### 2.2: Add Trust Policy

Click **Edit trust policy** and replace with:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:Yashwardhan-41007/RDS-databasereplication-prototype:*"
        }
      }
    }
  ]
}
```

**Replace:**
- `YOUR_ACCOUNT_ID` with your AWS account ID (12 digits)
- `Yashwardhan-41007/RDS-databasereplication-prototype` with your repo name

#### 2.3: Attach Permissions Policy

Click **Next** and attach this policy:

**Option A: Use Existing Policy (Simpler)**
- Attach: `AmazonSSMFullAccess`

**Option B: Create Custom Policy (More Secure)**

Create a new policy with this JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation",
        "ssm:ListCommandInvocations",
        "ssm:DescribeInstanceInformation"
      ],
      "Resource": [
        "arn:aws:ec2:ap-south-1:YOUR_ACCOUNT_ID:instance/i-0af51889228f2d442",
        "arn:aws:ssm:ap-south-1:*:document/AWS-RunShellScript",
        "arn:aws:ssm:ap-south-1:YOUR_ACCOUNT_ID:*"
      ]
    }
  ]
}
```

**Replace:**
- `YOUR_ACCOUNT_ID` with your AWS account ID
- `i-0af51889228f2d442` with your EC2 instance ID

#### 2.4: Name the Role

- **Role name:** `GitHubActions-RDS-Replication`
- **Description:** `Role for GitHub Actions to execute RDS replication via SSM`
- Click **Create role**

#### 2.5: Copy the Role ARN

After creating, copy the **Role ARN**. It looks like:
```
arn:aws:iam::123456789012:role/GitHubActions-RDS-Replication
```

---

### Step 3: Add Secrets to GitHub

Go to: `https://github.com/Yashwardhan-41007/RDS-databasereplication-prototype/settings/secrets/actions`

**Add these 2 secrets:**

#### Secret 1: AWS_ROLE_ARN
- **Name:** `AWS_ROLE_ARN`
- **Value:** The role ARN you copied (e.g., `arn:aws:iam::123456789012:role/GitHubActions-RDS-Replication`)

#### Secret 2: SSM_INSTANCE_ID
- **Name:** `SSM_INSTANCE_ID`
- **Value:** `i-0af51889228f2d442`

---

### Step 4: Verify EC2 Instance

The EC2 instance (`i-0af51889228f2d442`) needs:
- ✅ SSM Agent running
- ✅ IAM role with SSM permissions
- ✅ MySQL client installed

**Quick verification:**
```bash
# SSH to instance
ssh -i buildpiper.pem ubuntu@your-bastion-host

# Check SSM agent
sudo systemctl status amazon-ssm-agent

# Check MySQL
mysql --version

# If MySQL not installed
sudo apt-get update && sudo apt-get install -y mysql-client
```

---

### Step 5: Test the Workflow!

1. Commit and push the updated workflow
2. Go to **Actions** tab
3. Run the **RDS Replication** workflow
4. Fill in database details
5. ✅ It should work without any access keys!

---

## 🔍 How OIDC Works

### Traditional Approach (Access Keys):
```
1. Create IAM user
2. Generate access keys
3. Store keys in GitHub secrets
4. Keys are long-lived (risky!)
5. Manual rotation needed
```

### OIDC Approach (IAM Roles):
```
1. GitHub generates OIDC token (per workflow run)
2. GitHub sends token to AWS STS
3. AWS verifies token is from your repo
4. AWS issues temporary credentials (valid 1 hour)
5. Credentials auto-expire
6. No secrets to manage!
```

---

## 🛠️ Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Cause:** Trust policy doesn't allow your repository

**Fix:**
1. Go to IAM → Roles → Your role
2. **Trust relationships** tab → **Edit trust policy**
3. Verify the `token.actions.githubusercontent.com:sub` matches your repo:
   ```json
   "StringLike": {
     "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
   }
   ```

---

### Error: "User is not authorized to perform: ssm:SendCommand"

**Cause:** IAM role doesn't have SSM permissions

**Fix:**
1. Go to IAM → Roles → Your role
2. **Permissions** tab → **Add permissions**
3. Attach `AmazonSSMFullAccess` or custom SSM policy

---

### Error: "No OIDC provider found"

**Cause:** OIDC provider not set up in AWS account

**Fix:**
1. Go to IAM → Identity providers
2. Create OIDC provider (see Step 1 above)
3. Your company's AWS admin may need to do this

---

### Workflow Still Asks for AWS_ACCESS_KEY_ID

**Cause:** Old workflow version

**Fix:**
1. Pull latest changes: `git pull`
2. Verify workflow uses `role-to-assume` not `aws-access-key-id`
3. Commit and push if needed

---

## 📊 Comparison: Setup Complexity

### Access Keys Setup:
```
1. Create IAM user (2 min)
2. Generate access keys (1 min)
3. Add 2 secrets to GitHub (1 min)
Total: 4 minutes
```

### IAM Role Setup (OIDC):
```
1. Create OIDC provider (one-time, 2 min)
2. Create IAM role (5 min)
3. Add 1 secret to GitHub (1 min)
Total: 8 minutes (but more secure!)
```

**Worth the extra 4 minutes for:**
- ✅ No credential rotation needed
- ✅ Temporary credentials only
- ✅ Better audit trail
- ✅ AWS best practice

---

## 🔐 Security Best Practices

### ✅ Do This:
1. **Restrict role to specific repo** in trust policy
2. **Use least privilege** permissions (custom policy)
3. **Enable CloudTrail** to audit role usage
4. **Restrict to specific branches** (optional):
   ```json
   "StringLike": {
     "token.actions.githubusercontent.com:sub": "repo:ORG/REPO:ref:refs/heads/main"
   }
   ```

### ❌ Don't Do This:
1. Don't use `*` in trust policy (allows any repo)
2. Don't attach `AdministratorAccess` policy
3. Don't skip OIDC provider setup (falls back to keys)

---

## 📞 Need Help from Your Company?

Ask your AWS admin for:

1. **OIDC Provider Setup** (if not exists)
   - "Can you create an OIDC identity provider for GitHub Actions?"
   - Provider URL: `https://token.actions.githubusercontent.com`

2. **IAM Role Creation** (if you don't have permissions)
   - "Can you create an IAM role for GitHub Actions with SSM permissions?"
   - Share this guide with them

3. **Role ARN**
   - "What's the ARN of the role I should use?"
   - Add it to GitHub secrets as `AWS_ROLE_ARN`

---

## ✅ Verification Checklist

Before running the workflow:

- [ ] OIDC provider exists in AWS account
- [ ] IAM role created with correct trust policy
- [ ] IAM role has SSM permissions
- [ ] Trust policy allows your specific repository
- [ ] `AWS_ROLE_ARN` secret added to GitHub
- [ ] `SSM_INSTANCE_ID` secret added to GitHub
- [ ] EC2 instance has SSM agent running
- [ ] EC2 instance has MySQL client installed
- [ ] Workflow file has `permissions: id-token: write`

---

## 🎉 You're Done!

This is the **most secure** way to run GitHub Actions with AWS. No access keys to manage, no rotation needed, and full audit trail!

**Run the workflow and enjoy keyless authentication!** 🚀
