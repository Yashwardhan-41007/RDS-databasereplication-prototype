# SSH Tunnel Setup Guide

This workflow uses SSH tunnels through your bastion host to access private RDS instances.

## 🔑 How It Works

```
GitHub Actions (Cloud)
         │
         │ SSH Connection
         ▼
    Bastion Host (EC2)
         │
         │ Port Forwarding
         ├─► Source RDS (port 3307 → 3306)
         └─► Target RDS (port 3308 → 3306)
```

GitHub Actions creates SSH tunnels that forward:
- Local port **3307** → Source RDS port **3306** (through bastion)
- Local port **3308** → Target RDS port **3306** (through bastion)

Then connects to `localhost:3307` and `localhost:3308` which are actually your private RDS instances!

---

## 📋 Setup Steps

### Step 1: Get Your SSH Private Key Content

```bash
cat buildpiper.pem
```

Copy the **entire output**, including:
```
-----BEGIN RSA PRIVATE KEY-----
... (all the key content) ...
-----END RSA PRIVATE KEY-----
```

### Step 2: Add Secrets to GitHub

1. Go to your repository:
   ```
   https://github.com/Yashwardhan-41007/RDS-databasereplication-prototype/settings/secrets/actions
   ```

2. Click **"New repository secret"** and add these **3 secrets**:

#### Secret 1: BASTION_SSH_KEY
- **Name:** `BASTION_SSH_KEY`
- **Value:** Paste the entire private key content from Step 1

#### Secret 2: BASTION_HOST
- **Name:** `BASTION_HOST`
- **Value:** Your bastion hostname (e.g., `ec2-xx-xxx-xxx-xxx.ap-south-1.compute.amazonaws.com`)

#### Secret 3: BASTION_USER
- **Name:** `BASTION_USER`
- **Value:** `ubuntu` (or whatever user you SSH with)

### Step 3: Commit and Push the Workflow

```bash
cd /Users/a41007/Documents/rds-replication-automation

git add .github/workflows/rds-replication.yml
git commit -m "Add SSH tunnel support for private RDS access"
git push
```

### Step 4: Test It!

1. Go to **Actions** tab on GitHub
2. Click **"RDS Replication"** workflow
3. Click **"Run workflow"**
4. Fill in:
   - Database name
   - Source RDS **private** endpoint (e.g., `db.internal.rds.amazonaws.com`)
   - Source credentials
   - Target RDS **private** endpoint
   - Target credentials
5. Click **"Run workflow"**

---

## 🔍 What Happens Behind the Scenes

### Step-by-Step Execution:

1. **GitHub Actions starts** on GitHub's cloud runner

2. **Setup SSH Tunnel step:**
   ```bash
   # Creates SSH key file from secret
   echo "$SSH_KEY" > ~/.ssh/bastion_key
   
   # Establishes tunnels
   ssh -i ~/.ssh/bastion_key -f -N -L 3307:source-rds:3306 ubuntu@bastion
   ssh -i ~/.ssh/bastion_key -f -N -L 3308:target-rds:3306 ubuntu@bastion
   ```

3. **Test Connections step:**
   ```bash
   # Connects to localhost:3307 which tunnels to source RDS
   mysql -h 127.0.0.1 -P 3307 -u admin -p
   
   # Connects to localhost:3308 which tunnels to target RDS
   mysql -h 127.0.0.1 -P 3308 -u admin -p
   ```

4. **Replication step:**
   ```bash
   # Dumps from localhost:3307 (actually source RDS through tunnel)
   mysqldump -h 127.0.0.1 -P 3307 ... | 
   
   # Restores to localhost:3308 (actually target RDS through tunnel)
   mysql -h 127.0.0.1 -P 3308 ...
   ```

---

## 🎯 Advantages of This Approach

### ✅ Pros:
- **No self-hosted runner needed** - Runs in GitHub's cloud
- **Works with private RDS** - Tunnels through bastion
- **Simple setup** - Just add 3 secrets
- **Secure** - SSH key stored as encrypted secret
- **Flexible** - Can access any resource behind bastion

### ⚠️ Considerations:
- **Bastion must be accessible** from internet (port 22)
- **SSH key stored in GitHub** (encrypted, but still in GitHub)
- **Slightly slower** than self-hosted runner (extra hop)

---

## 🛠️ Troubleshooting

### "Permission denied (publickey)" Error

**Cause:** SSH key format issue or wrong key

**Fix:**
1. Verify you copied the **entire** key including headers
2. Check the key has correct permissions on bastion:
   ```bash
   chmod 600 ~/.ssh/authorized_keys
   ```

### "Connection refused" Error

**Cause:** Bastion security group doesn't allow SSH from GitHub

**Fix:**
1. Go to AWS Console → EC2 → Security Groups
2. Find bastion's security group
3. Add inbound rule:
   - **Type:** SSH (port 22)
   - **Source:** `0.0.0.0/0` (or GitHub's IP ranges)

### "Host key verification failed" Error

**Cause:** Bastion not in known_hosts

**Fix:** The workflow already handles this with `ssh-keyscan`, but if it still fails:
```yaml
# Add to workflow before SSH tunnel:
- run: ssh-keyscan -H ${{ secrets.BASTION_HOST }} >> ~/.ssh/known_hosts
```

### Tunnel Fails Silently

**Cause:** RDS hostname not resolvable from bastion

**Fix:**
1. SSH to bastion manually
2. Test DNS resolution:
   ```bash
   nslookup your-rds-endpoint.rds.amazonaws.com
   ```
3. If it fails, use the private IP instead of hostname

---

## 🔐 Security Notes

### What's Secure:
- ✅ Passwords masked in logs
- ✅ SSH key encrypted at rest in GitHub
- ✅ SSH key only accessible during workflow run
- ✅ Tunnels are temporary (closed after workflow)

### What to Consider:
- ⚠️ SSH key stored in GitHub (encrypted)
- ⚠️ Bastion must accept SSH from internet
- ⚠️ Consider IP allowlisting for bastion SSH

### Best Practices:
1. **Use a dedicated SSH key** for GitHub Actions (not your personal key)
2. **Restrict bastion SSH** to GitHub's IP ranges if possible
3. **Rotate keys regularly**
4. **Monitor bastion SSH logs** for unauthorized access
5. **Use read-only RDS users** when possible

---

## 📊 Comparison: SSH Tunnel vs Self-Hosted Runner

| Aspect | SSH Tunnel | Self-Hosted Runner |
|--------|------------|-------------------|
| **Setup** | Add 3 secrets | Install runner on bastion |
| **Maintenance** | None | Runner needs updates |
| **Speed** | Slower (extra hop) | Faster (direct) |
| **Security** | Key in GitHub | No keys in GitHub |
| **Bastion requirement** | Must allow SSH | Must run runner |
| **Best for** | Occasional use | Frequent use |

---

## ✅ Verification Checklist

Before running the workflow, verify:

- [ ] SSH key added to GitHub secrets (`BASTION_SSH_KEY`)
- [ ] Bastion host added to GitHub secrets (`BASTION_HOST`)
- [ ] Bastion user added to GitHub secrets (`BASTION_USER`)
- [ ] Bastion security group allows SSH (port 22) from internet
- [ ] You can manually SSH to bastion with the key
- [ ] Bastion can reach both source and target RDS
- [ ] Workflow file committed and pushed

---

## 🎉 You're Ready!

Once all secrets are added, go to GitHub Actions and run the workflow. It should now work with your private RDS instances!

**Questions?** Check the workflow logs for detailed error messages.
