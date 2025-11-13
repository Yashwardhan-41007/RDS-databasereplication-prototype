# RDS Replication Automation

**100% Free** GitHub Actions automation for MySQL RDS replication between private subnets.

## 🚀 Quick Start (GitHub Actions)

### 2 Simple Steps:

1. **Push this repo to GitHub**
2. **Click "Run workflow"** and enter credentials manually

**📖 Full guide:** See [WORKFLOW_USAGE.md](WORKFLOW_USAGE.md)

**🔒 Security:**
- ✅ Passwords automatically masked in logs (appear as `***`)
- ✅ No credentials stored in repository
- ✅ Manual entry each time you run

---

## Alternative: Local Scripts

If you prefer running locally instead of GitHub Actions:

### Option 1: One-Liner
```bash
./quick_replicate.sh src_host src_user src_pass tgt_host tgt_user tgt_pass database_name
```

### Option 2: Interactive Script
```bash
./rds_replicate_auto.sh
```

## 📁 Files Overview

| File | Purpose |
|------|---------|
| `rds_replicate_auto.sh` | **Main script** - Full featured with logging |
| `quick_replicate.sh` | **Simple version** - Quick one-command replication |
| `replication_config.env` | **Config template** - Store your credentials |
| `setup_cron.sh` | **Scheduler** - Set up automatic daily runs |
| `.github/workflows/rds-replication.yml` | **GitHub Actions** - Free CI/CD automation |

## 🔧 Setup Instructions

### 1. Make Scripts Executable
```bash
chmod +x *.sh
```

### 2. Set Up Configuration
```bash
# Copy and edit config file
cp replication_config.env production.env
nano production.env

# Add your RDS endpoints and credentials
SRC_HOST="source-rds.xxx.ap-south-1.rds.amazonaws.com"
SRC_USER="admin"
SRC_PASS="your-source-password"
# ... etc
```

### 3. Test Connection
```bash
# Test with your config
./rds_replicate_auto.sh production.env
```

## ⏰ Scheduling Options

### Cron Job (Local Machine)
```bash
# Set up daily replication at 2 AM
./setup_cron.sh
```

### GitHub Actions (Free Cloud)
1. Push this repo to GitHub
2. Go to Actions tab → Run workflow
3. Enter credentials manually each time
4. No secrets stored in repository

### AWS Lambda (Free Tier)
- Upload `quick_replicate.sh` as Lambda function
- Use CloudWatch Events for scheduling
- 1M free requests per month

## 📊 Features

### ✅ Included
- **Automatic backup** before replication
- **Connection testing** before starting
- **Verification** after replication
- **Detailed logging** with timestamps
- **Multiple database** support
- **Error handling** and rollback
- **Flexible configuration**

### 🔒 Security
- **Passwords masked in logs** - Never visible in GitHub Actions output
- **No stored credentials** - Manual entry each time
- Config files can be secured with file permissions
- Backup files for safety

## 📋 Examples

### Replicate Single Database
```bash
./quick_replicate.sh \
  source-rds.amazonaws.com admin pass123 \
  target-rds.amazonaws.com admin pass456 \
  production_db
```

### Replicate All Databases
```bash
# Edit config file with DB_LIST="all"
./rds_replicate_auto.sh my_config.env
```

### Scheduled Replication
```bash
# Set up daily at 2 AM
./setup_cron.sh

# Check cron job
crontab -l
```

## 🆘 Troubleshooting

### Connection Issues
- Verify security groups allow MySQL traffic (port 3306)
- Check RDS subnet routing and NACLs
- Ensure credentials are correct

### Permission Issues
- RDS user needs `SELECT`, `LOCK TABLES`, `SHOW VIEW` on source
- RDS user needs `CREATE`, `DROP`, `INSERT`, `UPDATE`, `DELETE` on target

### Verification Failures
- Check logs in `./logs/` directory
- Compare table counts manually
- Verify triggers and stored procedures

## 💰 Cost Breakdown

| Service | Cost |
|---------|------|
| **Shell Scripts** | $0 |
| **GitHub Actions** | $0 (2000 minutes/month free) |
| **Cron Jobs** | $0 |
| **AWS Lambda** | $0 (1M requests/month free) |
| **Data Transfer** | Only RDS → RDS within same region |

## 🔄 Comparison with Alternatives

| Solution | Cost | Setup | Real-time | Best For |
|----------|------|-------|-----------|----------|
| **These Scripts** | Free | Easy | No | Batch replication |
| **AWS DMS** | ~$50/month | Medium | Yes | Production workloads |
| **Jenkins** | EC2 costs | Complex | No | Enterprise environments |
| **Lambda + EventBridge** | ~$1/month | Medium | No | Serverless preference |

## 🎯 Next Steps

1. **Test** with a small database first
2. **Schedule** regular replications
3. **Monitor** logs for any issues
4. **Set up** notifications (Slack/email)
5. **Document** your specific configuration

## 📞 Support

If you encounter issues:
1. Check the log files in `./logs/`
2. Test connections manually with `mysql` command
3. Verify RDS security groups and networking
4. Ensure sufficient disk space for backups

---

**Ready to automate your RDS replication? Start with the quick script and scale up as needed!**
