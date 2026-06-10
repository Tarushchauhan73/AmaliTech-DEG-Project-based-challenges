# Kora Analytics API - Deployment Documentation (Railway)

## Overview

This document describes how to deploy the Kora Analytics API on **Railway**, a modern cloud platform designed for developers. Railway simplifies deployment by removing infrastructure complexity while maintaining security and reliability.

---

## 1. Cloud Provider & Infrastructure Choice

### Selected Provider: Railway

**Why Railway?**
- **Zero Infrastructure Management** — No VMs, security groups, or networking to configure
- **GitHub Native Integration** — Deploy directly from your GitHub repository with one click
- **Automatic Scaling** — Handles traffic spikes without manual intervention
- **Built-in Monitoring** — Logs, metrics, and health checks out of the box
- **Free Tier** — $5/month credit, perfect for MVPs and startups
- **Fast Deployments** — From GitHub push to live in <5 minutes
- **Environment Variables** — Simple UI for managing secrets and configuration
- **SSL/HTTPS Included** — Automatic SSL certificates for all deployments
- **Cost-Effective** — Simple, transparent pricing with no surprise charges

### Infrastructure Components

| Component | Service | Notes |
|-----------|---------|-------|
| **Container Platform** | Railway Native | Runs your Dockerfile without managing infrastructure |
| **Image Registry** | Built-in | Automatic image storage (no separate registry needed) |
| **Domain** | Railway subdomain | Auto-generated domain + custom domain support |
| **SSL/TLS** | Automatic | HTTPS enabled by default |
| **Environment Vars** | Railway Dashboard | Secure secret management |
| **Logs** | Built-in | Real-time logs in Railway dashboard |
| **Monitoring** | Built-in | Automatic health checks and metrics |

---

## 2. Railway Setup (5-Minute Quick Start)

### Prerequisites

- GitHub account (with your forked repository)
- Railway account (free to create)

### Step 1: Create a Railway Account

1. Visit [railway.app](https://railway.app)
2. Click **"Start Project"** → Choose **"Deploy from GitHub"**
3. Sign up with GitHub (easiest option) or email
4. Authorize Railway to access your GitHub repositories

### Step 2: Create a New Project

1. In Railway dashboard, click **"Create a new project"**
2. Select **"Deploy from GitHub repo"**
3. Choose your repository (`AmaliTech-DEG-Project-based-challenges`)
4. Click **"Deploy"**

Railway will automatically:
- Detect the `Dockerfile`
- Build the Docker image
- Start the container
- Assign a public URL

**Wait 2-3 minutes for the first deployment to complete.**

### Step 3: Configure Environment Variables

1. In Railway dashboard, click your **project name**
2. Go to **Variables** tab
3. Add these variables:
   ```
   PORT=3000
   NODE_ENV=production
   ```
4. Click **"Save"** — Railway automatically redeploys

### Step 4: Access Your Deployment

Railway generates a URL like:
```
https://kora-analytics-api-production.railway.app
```

Test it immediately:
```bash
# Health check (required for submission)
curl https://kora-analytics-api-production.railway.app/health
# Response: {"status":"ok"}

# Get metrics
curl https://kora-analytics-api-production.railway.app/metrics
# Response: {"uptime_seconds":45,"memory_mb":52,"node_version":"v18.x.x"}

# Send data
curl -X POST https://kora-analytics-api-production.railway.app/data \
  -H "Content-Type: application/json" \
  -d '{"shipment_id":"KOR-001","status":"in_transit"}'
# Response: {"received":{"shipment_id":"KOR-001","status":"in_transit"}}
```

**That's it!** Your app is live on the internet with HTTPS enabled.

---

## 3. GitHub Actions Integration

### Required Secrets Setup

In your GitHub repository (Settings → Secrets → Repository secrets), add:

| Secret Name | Value | How to Get |
|-------------|-------|-----------|
| `RAILWAY_TOKEN` | Your Railway API token | See section 3.1 below |

### 3.1 Getting Your Railway Token

1. Go to [railway.app/account/tokens](https://railway.app/account/tokens)
2. Click **"Create Token"**
3. Give it a name: `GitHub Deployment`
4. Copy the token
5. In GitHub: Settings → Secrets → New repository secret
   - Name: `RAILWAY_TOKEN`
   - Value: (paste the token)

### 3.2 Automatic Deployments

Now, every push to `main` branch will:

1. **Run Tests** — `npm test` executes
   - ✗ Fails → Pipeline stops, no deployment
   - ✓ Passes → Continue to deploy

2. **Deploy to Railway** — Using Railway CLI:
   - Build Docker image
   - Push to Railway
   - Start container
   - Health checks pass

**View deployment logs:**
- In your GitHub repository: **Actions** tab
- Click the latest workflow run
- See real-time build and deployment logs

**View application logs:**
- In Railway dashboard: Click your project → **"Logs"** tab
- See real-time application output
- Filter by service or date range

---

## 4. Monitoring & Logs

### View Application Logs

**In Railway Dashboard:**
1. Project → **Logs** tab
2. See real-time logs from your container
3. Filter by date/time
4. Search for specific strings (e.g., errors)

**Example log output:**
```
Server running on port 3000
GET /health 200 - 1.234 ms
GET /metrics 200 - 0.892 ms
POST /data 200 - 2.341 ms
```

### Health Monitoring

Railway automatically monitors your service:
- Container status (running/restarting)
- Memory usage
- CPU usage
- Restarts count
- Response times

**View metrics:**
1. Project → **Deployments** tab
2. Click your active deployment
3. See real-time metrics

### Set Up Alerts (Optional)

1. Project → **Settings** → **Alerts**
2. Enable alerts for:
   - Service crashes
   - High memory usage
   - Deployment failures
3. Choose notification method (email, Slack, etc.)

---

## 5. Redeployment & Rollbacks

### Automatic Redeployment

Push to `main` branch:
```bash
git add .
git commit -m "Fix bug in API"
git push origin main
```

GitHub Actions will automatically:
1. Run tests
2. Deploy new version to Railway
3. Replace old container with new one

### Manual Redeployment

In Railway dashboard:
1. Project → **Deployments** tab
2. Click the **three dots** (...)
3. Select **"Redeploy"**

The previous version remains available if you need to rollback.

### Rollback to Previous Version

If the latest deployment has issues:

1. Railway dashboard → **Deployments** tab
2. Find the previous deployment (marked with date/time)
3. Click **three dots** → **"Rollback to this deployment"**

The previous Docker image immediately becomes active.

---

## 6. Troubleshooting

### Container won't start

**Check logs:**
1. Railway dashboard → Logs tab
2. Look for error messages (usually in first 10 lines)

**Common issues:**
- Port already in use → Check `PORT` environment variable
- Memory limit exceeded → Scale up in Settings
- Dependency installation failed → Check npm logs

**Solution:**
1. Fix the code locally
2. Test with `docker compose up --build`
3. Commit and push to trigger redeploy

### Application returns 500 errors

```bash
curl -v https://your-railway-url/health
```

**Check for:**
- Environment variables not set (check Railway dashboard)
- Port mismatch (must be 3000 in container)
- Memory constraints (upgrade plan if needed)

**View detailed logs:**
```
Railway dashboard → Logs → Filter by "error"
```

### Performance issues

**Monitor in Railway:**
1. Deployments tab → Click your active deployment
2. Scroll down to see:
   - Memory usage trend
   - CPU usage trend
   - Response times

**Scaling options:**
1. Settings tab → Scroll down
2. Upgrade memory allocation
3. Railway scales automatically; manual override available

---

## 7. Environment Variables

### Available Variables

Set these in Railway dashboard (Settings → Variables):

```env
# Application port (default 3000)
PORT=3000

# Node environment
NODE_ENV=production

# Optional: API keys, database URLs, etc.
API_KEY=your-secret-key
DATABASE_URL=postgres://...
```

### How to Update

1. Railway dashboard → **Variables** tab
2. Add or edit a variable
3. Click **Save**
4. Railway automatically redeploys

---

## 8. Custom Domain (Optional)

To use your own domain instead of Railway's subdomain:

### 8.1 Add Custom Domain in Railway

1. Railway dashboard → Your project → **Settings** tab
2. Scroll to **"Domains"** section
3. Click **"Add Custom Domain"**
4. Enter your domain (e.g., `api.yourdomain.com`)

### 8.2 Point Your Domain to Railway

In your domain registrar's DNS settings, add:

```
CNAME: api.yourdomain.com → kora-analytics-api-production.railway.app
```

Wait 5-10 minutes for DNS propagation, then:
```bash
curl https://api.yourdomain.com/health
```

---

## 9. Accessing Your Application

### From Browser

- **Railway subdomain:** `https://kora-analytics-api-production.railway.app`
- **Custom domain:** `https://api.yourdomain.com` (after DNS setup)

### From cURL/Code

```bash
# Health check (required for submission)
curl https://your-railway-url/health

# Expected response:
# {"status":"ok"}

# Metrics
curl https://your-railway-url/metrics

# Post data
curl -X POST https://your-railway-url/data \
  -H "Content-Type: application/json" \
  -d '{"test":"data"}'
```

---

## 10. Costs & Pricing

### Railway Free Tier

- **Monthly Credit:** $5 (automatically applied)
- **Included:** 512MB RAM container, 1GB disk storage
- **Typical MVP Cost:** Free (within $5 credit)

### Usage Examples

| Scenario | Cost | Notes |
|----------|------|-------|
| Small MVP (< 100 req/day) | Free | Uses < $5 credit |
| Growing startup (1M req/month) | $10-20/month | Includes CPU and storage |
| Scale-up (10M req/month) | $50-100/month | Consider load balancing |

### View Current Usage

Railway dashboard → **Billing** tab:
- Current month spend
- Resource usage breakdown
- Upcoming charges

---

## 11. Security

### What Railway Provides

✅ **HTTPS/SSL** — Automatic, no configuration needed
✅ **DDoS Protection** — Included in platform
✅ **Secret Management** — Environment variables are encrypted
✅ **Network Isolation** — Containers isolated by default
✅ **Automatic Updates** — Platform security patches

### What You Should Do

✅ **Keep Railway Token Secret** — Treat like SSH key
✅ **Use Environment Variables** — Never hardcode secrets
✅ **Regular Updates** — Keep dependencies current
✅ **Monitor Logs** — Watch for suspicious activity

### No SSH/Firewall Configuration Needed

Unlike AWS:
- ❌ No security groups to configure
- ❌ No SSH ports to open/restrict
- ❌ No firewall rules
- ❌ No IAM users to create

Railway handles all networking security.

---

## 12. Architecture Comparison

### Before (Manual SSH + AWS EC2)
```
Code Push → GitHub Actions → SSH into EC2 → Pull Docker image → Restart container
                            ↓ (complex)
                    Manual security group setup
                    Manual firewall rules
                    Manual SSH key management
                    Manual health checks
```

### After (Railway)
```
Code Push → GitHub Actions → Deploy to Railway → Done ✓
                            ↓ (simple)
                    Automatic container scaling
                    Automatic SSL/HTTPS
                    Automatic health checks
                    Built-in logs & monitoring
                    One-click rollback
```

---

## 13. Getting Help

- **Railway Docs:** [docs.railway.app](https://docs.railway.app)
- **Railway Community:** [Discord server](https://discord.gg/railway)
- **GitHub Actions Logs:** In your repository Actions tab
- **Railway Support:** In-app chat support (pro plan)

---

## Revision History

| Date | Change | Notes |
|------|--------|-------|
| 2026-06-10 | Railway deployment guide | Complete simplification from AWS EC2 |

---

**Status:** ✨ Fully deployed on Railway with automatic GitHub integration.

For questions or issues, refer to [Railway Documentation](https://docs.railway.app) or this deployment guide.
                              │   running         │
                              └─────────┬─────────┘
                                        │
                                    ┌───▼────┐
                                    │ Internet│
                                    │ (HTTP)  │
                                    └────┬────┘
                                         │
                              ┌──────────▼──────────┐
                              │  Users/Clients     │
                              │ GET /health        │
                              │ GET /metrics       │
                              │ POST /data         │
                              └────────────────────┘
```

---

## 12. Security Checklist

- ✓ SSH port 22 restricted to your IP only (not 0.0.0.0/0)
- ✓ HTTP port 80 open to internet (for API access)
- ✓ No secrets (.pem files, tokens) committed to Git
- ✓ GitHub Actions secrets used for SSH key & registry auth
- ✓ Non-root user inside Docker container (nodejs user)
- ✓ Regular security updates via `apt-get upgrade`
- ✓ Container restart policy: `unless-stopped` (auto-recovery)

---

## 13. Next Steps for Production

1. **Add HTTPS:** Use AWS Certificate Manager + ALB (Application Load Balancer)
2. **Enable logging:** Forward Docker logs to CloudWatch or ELK stack
3. **Add monitoring:** Set up CloudWatch alarms for CPU, memory, and error rates
4. **Implement CI/CD for Terraform:** Use IaC to version your infrastructure
5. **Enable backups:** Backup EC2 instance volumes regularly
6. **Multi-region failover:** Deploy to multiple regions with Route 53 health checks

---

## Support & Troubleshooting

For issues, refer to:
- **Docker logs:** `docker logs kora-analytics-api`
- **GitHub Actions logs:** Repository → Actions → View run logs
- **AWS CloudWatch:** CloudWatch → Logs → Review instance metrics
- **SSH connectivity:** Ensure your IP is in Security Group inbound rules

---

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2026-06-10 | Initial deployment guide | DevOps Engineer |

