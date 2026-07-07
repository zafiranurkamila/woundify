# ✅ Deployment Checklist for Woundify Competition

## Pre-Deployment Testing (Local)

### Docker Installation
- [ ] Docker installed: `docker --version`
- [ ] Docker Compose installed: `docker-compose --version`

### Project Setup
- [ ] All files created:
  - [ ] `docker-compose.yml`
  - [ ] `.env.example`
  - [ ] `woundify-backend/Dockerfile`
  - [ ] `woundify-ai/Dockerfile`
  - [ ] `DEPLOYMENT.md`
  - [ ] `QUICK_START.md`
  - [ ] `deploy.sh`

### Local Deployment Test
```bash
# From project root
cp .env.example .env
docker-compose up -d --build
docker-compose ps  # All should show "Up"
```

- [ ] PostgreSQL container running
- [ ] AI Engine container running
- [ ] Backend container running
- [ ] No error messages in logs: `docker-compose logs`

### Service Health Checks
```bash
# Test Backend
curl http://localhost:8080/swagger-ui/index.html
```
- [ ] Backend returns 200 OK
- [ ] Swagger UI visible
- [ ] Can login with admin@woundify.com / admin

```bash
# Test AI Engine
curl http://localhost:8000/docs
```
- [ ] AI Engine returns FastAPI docs
- [ ] All endpoints listed

```bash
# Test Database
docker-compose exec postgres psql -U woundify -d woundify -c "SELECT 1"
```
- [ ] Database responds with "1"

### Mobile App Testing
- [ ] Build Flutter APK: `flutter build apk --release`
- [ ] APK created in `build/app/outputs/flutter-apk/`
- [ ] Update `lib/api_service.dart` with localhost IP for testing
- [ ] Mobile app can login
- [ ] Mobile app can submit patient data
- [ ] Predictions work correctly

### Database Seeding
- [ ] Login as admin@woundify.com / admin
- [ ] Verify patient list loads
- [ ] Verify lab data exists
- [ ] Check epidemiological data populated

---

## VPS Deployment Preparation

### VPS Selection
- [ ] VPS provider selected (DigitalOcean, Linode, AWS EC2, etc.)
- [ ] Ubuntu 22.04 LTS image selected
- [ ] Minimum 2GB RAM allocated
- [ ] SSH access confirmed
- [ ] IP address noted: `____.____.____.____`

### Domain Setup (Optional but recommended)
- [ ] Domain registered or using IP address
- [ ] DNS pointing to VPS IP (if domain)
- [ ] Noted VPS URL: `http://your_domain_or_ip`

### VPS Access
```bash
ssh root@your_vps_ip
```
- [ ] SSH connection successful
- [ ] Can execute commands

---

## VPS Deployment Steps

### Step 1: System Setup
```bash
apt update && apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```
- [ ] Docker installed
- [ ] Docker Compose installed
- [ ] Commands executable: `docker --version && docker-compose --version`

### Step 2: Project Deployment
```bash
cd /opt
git clone https://github.com/yourname/woundify.git
cd woundify
cp .env.example .env
nano .env  # IMPORTANT: Change DB_PASSWORD!
```
- [ ] Project cloned
- [ ] `.env` file created
- [ ] `.env` contains strong DB_PASSWORD
- [ ] GEMINI_API_KEY set (if available)

### Step 3: Service Launch
```bash
docker-compose up -d --build
```
- [ ] Build process completed without errors
- [ ] All containers running: `docker-compose ps`
- [ ] No "Exited" status in containers

### Step 4: Verification on VPS
```bash
# Check services
docker-compose ps

# Check logs
docker-compose logs

# Test endpoints from VPS itself
curl http://localhost:8080/swagger-ui/index.html
curl http://localhost:8000/docs
```
- [ ] All containers show "Up"
- [ ] No critical errors in logs
- [ ] Backend responds
- [ ] AI Engine responds
- [ ] Database healthy

### Step 5: External Access Test
```bash
# From your laptop, test VPS endpoints
curl http://your_vps_ip:8080/swagger-ui/index.html
curl http://your_vps_ip:8000/docs
```
- [ ] Backend accessible from external network
- [ ] AI Engine accessible from external network
- [ ] Database NOT accessible from external (🔐 Good!)

---

## Domain & SSL Setup (Recommended for Production)

### Nginx Reverse Proxy
```bash
sudo apt install nginx certbot python3-certbot-nginx -y
```
- [ ] Nginx installed

```bash
# Create Nginx config
sudo nano /etc/nginx/sites-available/woundify
# [Paste config from DEPLOYMENT.md]

# Enable site
sudo ln -s /etc/nginx/sites-available/woundify /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```
- [ ] Nginx config created
- [ ] Config tested without errors
- [ ] Nginx restarted

### SSL Certificate (If using domain)
```bash
sudo certbot certbot --nginx -d your_domain.com
```
- [ ] SSL certificate obtained
- [ ] Auto-renewal configured
- [ ] HTTPS working: `curl https://your_domain.com`

---

## Post-Deployment Verification

### Comprehensive Health Check
- [ ] Backend Swagger API: `http://your_vps:8080/swagger-ui`
- [ ] AI Engine Docs: `http://your_vps:8000/docs`
- [ ] Mobile app installed and tested
- [ ] Login successful (admin@woundify.com / admin)
- [ ] Can add patient records
- [ ] Can trigger predictions
- [ ] Can view results

### Database Verification
```bash
docker-compose exec postgres psql -U woundify -d woundify
```
```sql
\dt                    -- List all tables
SELECT COUNT(*) FROM users;           -- Check users
SELECT COUNT(*) FROM patients;        -- Check patients
SELECT COUNT(*) FROM predictions;     -- Check predictions
\q                     -- Exit
```
- [ ] All expected tables present
- [ ] Data populated in tables
- [ ] Seeded admin user exists

### Performance Baseline
```bash
docker stats --no-stream > baseline.txt
```
- [ ] Baseline metrics noted
- [ ] CPU usage < 50%
- [ ] Memory usage < 70%
- [ ] No process at 100%

### Monitoring Setup
```bash
# Create monitoring script
cat > /opt/woundify/monitor.sh << 'EOF'
#!/bin/bash
while true; do
  docker-compose ps
  docker stats --no-stream
  sleep 60
done
EOF
chmod +x /opt/woundify/monitor.sh
```
- [ ] Monitoring script created
- [ ] Can be run to check health

---

## Backup & Recovery

### Database Backup
```bash
docker-compose exec postgres pg_dump -U woundify woundify > /opt/woundify/backup_$(date +%Y%m%d_%H%M%S).sql
```
- [ ] Backup created successfully
- [ ] Backup file readable
- [ ] Multiple backups kept (rotate old ones)

### Backup Restoration (if needed)
```bash
docker-compose exec -T postgres psql -U woundify woundify < backup_file.sql
```
- [ ] Restore process tested
- [ ] Can recover from backup

### Configuration Backup
- [ ] `.env` file backed up (locally, NOT in git!)
- [ ] `docker-compose.yml` backed up
- [ ] Nginx config backed up (if applicable)

---

## Competition Day Preparation

### Final Checks (24 hours before)
- [ ] All services running without restart for 24 hours
- [ ] No errors in logs
- [ ] Database size stable
- [ ] Disk space > 20% free
- [ ] Memory stable < 70%

### Documentation Ready
- [ ] README.md updated with deployment info
- [ ] API documentation (Swagger) accessible
- [ ] Credentials documented (kept secure)
- [ ] Known issues documented

### Team Preparation
- [ ] All team members know how to:
  - [ ] SSH to VPS
  - [ ] Check service status: `docker-compose ps`
  - [ ] View logs: `docker-compose logs`
  - [ ] Restart if needed: `docker-compose restart`
  - [ ] Backup database
  - [ ] Restore from backup

### Mobile App Distribution
- [ ] APK signed and ready to distribute
- [ ] Installation instructions prepared
- [ ] QR code with APK link ready (if applicable)
- [ ] Test devices prepared

### Emergency Contacts
- [ ] VPS provider support number noted
- [ ] Domain registrar contact info
- [ ] Team member contact list
- [ ] Escalation procedure documented

---

## Troubleshooting Preparation

### Common Issues & Quick Fixes
Reference: See `DEPLOYMENT.md` → Troubleshooting section

Quick commands to know:
```bash
# Stop everything
docker-compose down

# Start everything
docker-compose up -d --build

# View logs
docker-compose logs -f backend

# Restart single service
docker-compose restart backend

# Database reset (⚠️ DESTRUCTIVE)
docker-compose down -v
docker-compose up -d --build
```

- [ ] Commands copied to notepad
- [ ] Procedures practiced
- [ ] Rollback plan understood

---

## Go-Live Checklist (Day Before Competition)

### Services Status
- [ ] `docker-compose ps` shows all "Up"
- [ ] Logs show no errors in last hour
- [ ] CPU/Memory usage normal

### API Endpoints
- [ ] Backend Swagger loading in < 2s
- [ ] AI Engine docs loading in < 2s
- [ ] All endpoints responding

### Mobile App
- [ ] Apk installed on test devices
- [ ] Can login with admin account
- [ ] Can perform full workflow:
  - [ ] Add patient
  - [ ] Input lab data
  - [ ] Submit for prediction
  - [ ] View prediction results

### Data Integrity
- [ ] Database has all seeded data
- [ ] Can query patient records
- [ ] Can query predictions
- [ ] Can query epidemiological data

### Documentation
- [ ] API docs updated
- [ ] System diagrams correct
- [ ] Deployment documented
- [ ] Known limitations noted

### Monitoring
- [ ] Monitoring script running
- [ ] Backup script scheduled
- [ ] Alert system configured (if applicable)

---

## Sign-Off

**Deployment Approved By:** ___________________

**Date:** ___________________

**VPS URL/Domain:** ___________________

**Admin Credentials:** (Stored securely elsewhere, not here!)

**Backup Location:** ___________________

**Emergency Contact:** ___________________

---

## Quick Reference During Competition

### Emergency Commands
```bash
# Check status
docker-compose ps

# View all logs
docker-compose logs | tail -100

# Restart all services
docker-compose restart

# View resource usage
docker stats

# Backup database
docker-compose exec postgres pg_dump -U woundify woundify > emergency_backup.sql
```

### Access Points
- Frontend (mobile): Distributed as APK
- Backend API: http://your_domain:8080/swagger-ui
- AI Engine: http://your_domain:8000/docs
- Database: Internal only (5432)

### Key Files
- Configuration: `/opt/woundify/.env`
- Docker Compose: `/opt/woundify/docker-compose.yml`
- Logs: `docker-compose logs`
- Backups: `/opt/woundify/backup_*.sql`

---

**Status: Ready for Competition! 🎉**
