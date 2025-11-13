# Troubleshooting Guide

## 🔍 Common Issues and Solutions

---

## Issue 1: SSH Tunnel Setup Fails

### Error Message:
```
Error: Process completed with exit code 1.
```
At the "Setup SSH Tunnel" step.

### Possible Causes & Solutions:

#### A. SSH Key Format Issue

**Symptom:** "SSH key format invalid" error

**Solution:**
1. Verify you copied the **entire** SSH key including headers:
   ```
   -----BEGIN RSA PRIVATE KEY-----
   ... (key content) ...
   -----END RSA PRIVATE KEY-----
   ```

2. Check for extra spaces or newlines:
   ```bash
   # View your key file
   cat buildpiper.pem
   
   # Should start with -----BEGIN and end with -----END
   ```

3. Re-add the secret:
   - Go to GitHub → Settings → Secrets → Actions
   - Delete `BASTION_SSH_KEY`
   - Create it again with the correct content

#### B. Wrong Bastion Host

**Symptom:** "SSH connection to bastion failed"

**Solution:**
1. Verify the hostname:
   ```bash
   # Test from your local machine
   ssh -i buildpiper.pem ubuntu@your-bastion-host
   ```

2. Check the secret value:
   - GitHub → Settings → Secrets → Actions
   - `BASTION_HOST` should be just the hostname, e.g.:
     ```
     ec2-13-232-xxx-xxx.ap-south-1.compute.amazonaws.com
     ```
   - **NOT** with `ubuntu@` prefix
   - **NOT** with `ssh://` prefix

#### C. Wrong Username

**Symptom:** "Permission denied" or "SSH connection failed"

**Solution:**
1. Check what user you normally use:
   ```bash
   # If you SSH like this:
   ssh -i buildpiper.pem ubuntu@bastion
   # Then BASTION_USER should be: ubuntu
   
   # If you SSH like this:
   ssh -i buildpiper.pem ec2-user@bastion
   # Then BASTION_USER should be: ec2-user
   ```

2. Common usernames by OS:
   - Ubuntu: `ubuntu`
   - Amazon Linux: `ec2-user`
   - Debian: `admin`
   - CentOS: `centos`

#### D. Bastion Security Group Blocks GitHub

**Symptom:** "Connection timed out" or "Connection refused"

**Solution:**
1. Go to AWS Console → EC2 → Security Groups
2. Find your bastion's security group
3. Check inbound rules for port 22 (SSH)
4. Add rule if missing:
   - **Type:** SSH
   - **Protocol:** TCP
   - **Port:** 22
   - **Source:** `0.0.0.0/0` (or GitHub's IP ranges)

#### E. SSH Key Doesn't Match

**Symptom:** "Permission denied (publickey)"

**Solution:**
1. Verify the key you're using:
   ```bash
   # Check the fingerprint
   ssh-keygen -lf buildpiper.pem
   ```

2. Compare with bastion's authorized keys:
   ```bash
   # SSH to bastion
   ssh -i buildpiper.pem ubuntu@bastion
   
   # Check authorized keys
   cat ~/.ssh/authorized_keys
   ```

3. Make sure you're copying the **private key** (buildpiper.pem), not the public key

---

## Issue 2: RDS Connection Fails Through Tunnel

### Error Message:
```
Testing source RDS connection (through SSH tunnel)...
Error: Process completed with exit code 1.
```

### Possible Causes & Solutions:

#### A. RDS Hostname Not Resolvable from Bastion

**Solution:**
1. SSH to bastion and test:
   ```bash
   ssh -i buildpiper.pem ubuntu@bastion
   
   # Test DNS resolution
   nslookup cars24-qa-mysql8-0-35.cbso2wac2573.ap-south-1.rds.amazonaws.com
   
   # Test connection
   mysql -h cars24-qa-mysql8-0-35.cbso2wac2573.ap-south-1.rds.amazonaws.com -u admin -p
   ```

2. If DNS fails, use private IP instead:
   - Get RDS private IP from AWS Console
   - Use IP instead of hostname in workflow inputs

#### B. RDS Security Group Blocks Bastion

**Solution:**
1. Go to AWS Console → RDS → Your Database → Connectivity
2. Click on the VPC security group
3. Check inbound rules for port 3306
4. Add rule if missing:
   - **Type:** MySQL/Aurora
   - **Port:** 3306
   - **Source:** Bastion's security group or private IP

#### C. Wrong RDS Credentials

**Solution:**
1. Verify credentials work manually:
   ```bash
   # From bastion
   mysql -h your-rds.amazonaws.com -u admin -p
   ```

2. Check for typos in workflow inputs
3. Verify user has proper permissions

---

## Issue 3: Tunnel Establishes But Connection Fails

### Error Message:
```
✅ SSH tunnels established successfully
Testing source RDS connection (through SSH tunnel)...
❌ Source connection failed
```

### Possible Causes & Solutions:

#### A. Tunnel Not Actually Working

**Solution:**
1. The workflow now checks with `netstat`, but if it still fails:
   ```bash
   # Manually test tunnel on your local machine
   ssh -i buildpiper.pem -L 3307:rds-host:3306 ubuntu@bastion
   
   # In another terminal
   mysql -h 127.0.0.1 -P 3307 -u admin -p
   ```

#### B. Port Already in Use

**Solution:**
- GitHub Actions runners are clean, so this shouldn't happen
- But if it does, the workflow will fail at tunnel creation

---

## Issue 4: Workflow Runs But No Data Replicated

### Possible Causes & Solutions:

#### A. Database Name Typo

**Solution:**
1. Check database exists on source:
   ```sql
   SHOW DATABASES;
   ```

2. Verify exact spelling (case-sensitive on some systems)

#### B. Insufficient Permissions

**Solution:**
1. Source user needs:
   - `SELECT`
   - `LOCK TABLES`
   - `SHOW VIEW`

2. Target user needs:
   - `CREATE`
   - `DROP`
   - `INSERT`
   - `UPDATE`
   - `DELETE`

3. Grant permissions:
   ```sql
   -- On source
   GRANT SELECT, LOCK TABLES, SHOW VIEW ON database_name.* TO 'user'@'%';
   
   -- On target
   GRANT ALL PRIVILEGES ON database_name.* TO 'user'@'%';
   FLUSH PRIVILEGES;
   ```

---

## 🔧 Manual Testing Steps

### Test 1: SSH to Bastion
```bash
ssh -i buildpiper.pem ubuntu@your-bastion-host
```
✅ Should connect successfully

### Test 2: RDS from Bastion
```bash
# From bastion
mysql -h your-rds.amazonaws.com -u admin -p
```
✅ Should connect to RDS

### Test 3: SSH Tunnel Locally
```bash
# On your local machine
ssh -i buildpiper.pem -L 3307:rds-host:3306 ubuntu@bastion

# In another terminal
mysql -h 127.0.0.1 -P 3307 -u admin -p
```
✅ Should connect to RDS through tunnel

### Test 4: Replication Manually
```bash
# From bastion
mysqldump -h source-rds -u admin -p --databases mydb | mysql -h target-rds -u admin -p
```
✅ Should replicate successfully

---

## 📋 Checklist Before Running Workflow

- [ ] SSH key added to GitHub secrets (`BASTION_SSH_KEY`)
- [ ] Bastion host added to GitHub secrets (`BASTION_HOST`)
- [ ] Bastion user added to GitHub secrets (`BASTION_USER`)
- [ ] Can manually SSH to bastion with the key
- [ ] Bastion security group allows SSH (port 22)
- [ ] Can connect to both RDS instances from bastion
- [ ] RDS security groups allow MySQL (port 3306) from bastion
- [ ] RDS credentials are correct
- [ ] Database exists on source RDS
- [ ] Users have proper permissions

---

## 🆘 Still Stuck?

### Enable Debug Logging

Add this to your workflow for more verbose output:

```yaml
- name: Setup SSH Tunnel
  env:
    SSH_KEY: ${{ secrets.BASTION_SSH_KEY }}
    BASTION_HOST: ${{ secrets.BASTION_HOST }}
    BASTION_USER: ${{ secrets.BASTION_USER }}
  run: |
    set -x  # Enable debug mode
    # ... rest of the commands
```

### Check GitHub Actions Logs

1. Go to Actions tab
2. Click on the failed run
3. Expand each step to see detailed output
4. Look for specific error messages

### Common Error Messages:

| Error | Meaning | Solution |
|-------|---------|----------|
| `Permission denied (publickey)` | SSH key doesn't match | Re-check SSH key secret |
| `Connection refused` | Port blocked | Check security groups |
| `Connection timed out` | Host unreachable | Check hostname/network |
| `Host key verification failed` | Known hosts issue | Workflow handles this, shouldn't happen |
| `Access denied for user` | Wrong MySQL credentials | Check RDS username/password |
| `Unknown database` | Database doesn't exist | Check database name spelling |

---

## 💡 Pro Tips

1. **Test locally first:** Always test SSH tunnel manually before using in workflow
2. **Check AWS Console:** Verify all security groups and network settings
3. **Use descriptive names:** Name your secrets clearly to avoid confusion
4. **Keep secrets updated:** Rotate keys regularly and update secrets
5. **Monitor logs:** Always check workflow logs for detailed error messages

---

## 📞 Need More Help?

If you're still having issues:

1. **Check the workflow logs** - They now have detailed error messages
2. **Test each component manually** - SSH, RDS connection, tunnel
3. **Verify all secrets** - Make sure they're correct in GitHub
4. **Check AWS settings** - Security groups, network ACLs, routing tables
