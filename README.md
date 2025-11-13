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

## 📁 Files Overview

| File | Purpose |
|------|---------|
| `.github/workflows/rds-replication.yml` | **GitHub Actions workflow** - Automated replication |
| `README.md` | **Main documentation** - Getting started guide |
| `WORKFLOW_USAGE.md` | **Usage guide** - Detailed instructions |

## 🔧 How It Works

The GitHub Actions workflow:
1. ✅ Tests connections to both RDS instances
2. 🔄 Dumps database from source using `mysqldump`
3. 📥 Restores to target database
4. ✔️ Verifies table counts match

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
- **Environment variables** - Credentials not exposed in command strings
- **Error suppression** - MySQL errors hidden from logs

## 📋 Usage Example

### Running the Workflow

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **RDS Replication** workflow
4. Click **Run workflow**
5. Fill in the form:
   - Database name (e.g., `production_db`)
   - Source RDS host, username, password
   - Target RDS host, username, password
6. Click **Run workflow** button
7. Monitor the progress in real-time

## 🆘 Troubleshooting

### Connection Issues
- Verify security groups allow MySQL traffic (port 3306)
- Check RDS subnet routing and NACLs
- Ensure credentials are correct

### Permission Issues
- RDS user needs `SELECT`, `LOCK TABLES`, `SHOW VIEW` on source
- RDS user needs `CREATE`, `DROP`, `INSERT`, `UPDATE`, `DELETE` on target

### Verification Failures
- Check GitHub Actions workflow logs
- Compare table counts manually
- Verify triggers and stored procedures

## 💰 Cost Breakdown

| Service | Cost |
|---------|------|
| **GitHub Actions** | $0 (2000 minutes/month free) |
| **Data Transfer** | Only RDS → RDS within same region |
| **Total** | **$0** 🎉 |

## 🔄 Comparison with Alternatives

| Solution | Cost | Setup | Real-time | Best For |
|----------|------|-------|-----------|----------|
| **This Solution** | Free | Easy | No | Manual/on-demand replication |
| **AWS DMS** | ~$50/month | Medium | Yes | Continuous replication |
| **Jenkins** | EC2 costs | Complex | No | Enterprise CI/CD |
| **Lambda + EventBridge** | ~$1/month | Medium | No | Scheduled automation |

## 🎯 Next Steps

1. **Test** with a small/dummy database first
2. **Verify** logs show passwords as `***`
3. **Monitor** GitHub Actions logs for any issues
4. **Document** your RDS endpoints for quick access
5. **Run** replications whenever needed

## 📞 Support

If you encounter issues:
1. Check the **GitHub Actions logs** for detailed error messages
2. Test connections manually with `mysql` command
3. Verify RDS security groups allow GitHub Actions IPs
4. Ensure credentials are correct

---

**Ready to replicate your RDS databases? Just push to GitHub and run the workflow!** 🚀
