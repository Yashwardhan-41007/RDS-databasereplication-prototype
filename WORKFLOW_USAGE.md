# GitHub Actions Workflow Usage Guide

## Overview
This workflow allows you to replicate RDS databases by manually entering credentials each time you run it. No credentials are stored in the repository.

## How to Use

### 1. Navigate to GitHub Actions
- Go to your repository on GitHub
- Click on the **Actions** tab
- Select **RDS Replication** workflow from the left sidebar

### 2. Run the Workflow
- Click the **Run workflow** button (top right)
- Fill in the required fields:

| Field | Description | Example |
|-------|-------------|---------|
| **Database name** | Name of the database to replicate | `production_db` |
| **Source RDS Host** | Source database endpoint | `source-rds.xxx.ap-south-1.rds.amazonaws.com` |
| **Source RDS Username** | Source database username | `admin` |
| **Source RDS Password** | Source database password | `your-password` |
| **Target RDS Host** | Target database endpoint | `target-rds.yyy.ap-south-1.rds.amazonaws.com` |
| **Target RDS Username** | Target database username | `admin` |
| **Target RDS Password** | Target database password | `your-password` |

### 3. Run and Monitor
- Click **Run workflow** (green button)
- The workflow will:
  1. Test connections to both databases
  2. Perform the replication using `mysqldump`
  3. Verify table counts match

## Security

**🔒 Password Protection:**
- Passwords are automatically masked in logs (appear as `***`)
- No credentials stored in the repository
- Manual entry each time ensures no accidental exposure

## Workflow Steps

The workflow performs these operations:

1. **Install MySQL Client** - Installs required tools
2. **Test Connections** - Validates connectivity to both databases
3. **Replicate Database** - Dumps source and restores to target
4. **Verify Replication** - Compares table counts

## Troubleshooting

### Connection Failures
- Verify security groups allow connections from GitHub Actions IPs
- Check that RDS instances are publicly accessible (or use VPN/bastion)
- Confirm credentials are correct

### Replication Errors
- Ensure target database has sufficient storage
- Check that database names don't conflict
- Verify user has necessary permissions (CREATE, INSERT, etc.)

## Example Run

```
Database name: production_db
Source RDS Host: prod-source.xxx.rds.amazonaws.com
Source RDS Username: admin
Source RDS Password: ••••••••
Target RDS Host: prod-target.yyy.rds.amazonaws.com
Target RDS Username: admin
Target RDS Password: ••••••••
```

## Best Practices

1. **Use read-only users** for source database when possible
2. **Test with non-production databases** first
3. **Review workflow logs** after each run
4. **Limit repository access** to trusted team members only
5. **Consider using temporary credentials** that expire after use
6. **Enable branch protection** to prevent unauthorized workflow modifications
