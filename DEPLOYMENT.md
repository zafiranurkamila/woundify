# 🚀 Woundify Deployment Guide

Panduan lengkap untuk deploy Woundify agar jalan 24/7 untuk kompetisi.

## 📋 Prerequisite

- **Docker** & **Docker Compose** installed
- **Git** (untuk clone/push repo)
- Akses ke VPS atau cloud platform (untuk 24/7 deployment)
- Domain atau IP address VPS

---

## Option 1: Local Testing dengan Docker Compose

Untuk test semua service berjalan dengan baik sebelum deploy ke VPS.

### Setup

1. **Clone/navigate ke project root**
   ```bash
   cd woundify
   ```

2. **Buat .env file dari template**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` dan set password DB yang kuat:
   ```
   DB_PASSWORD=your_secure_password_here
   ```

3. **Build & run semua service**
   ```bash
   docker-compose up --build
   ```

   Output yang benar:
   ```
   postgres            | database system is ready to accept connections
   ai-engine           | Uvicorn running on http://0.0.0.0:8000
   backend             | Started Application in X seconds
   ```

4. **Test endpoints**
   - Backend Swagger: http://localhost:8080/swagger-ui/index.html
   - AI Engine Docs: http://localhost:8000/docs
   - Database: localhost:5432

5. **Stop container**
   ```bash
   docker-compose down
   ```

---

## Option 2: Deploy ke VPS (Recommended untuk Kompetisi 24/7)

### A. Setup VPS (DigitalOcean / Linode / AWS EC2)

1. **Create Ubuntu 22.04 VPS** (minimal 2GB RAM recommended)

2. **SSH ke VPS**
   ```bash
   ssh root@your_vps_ip
   ```

3. **Install Docker & Docker Compose**
   ```bash
   # Update system
   apt update && apt upgrade -y

   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh

   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose

   # Verify installation
   docker --version
   docker-compose --version
   ```

### B. Deploy Project

1. **Clone project repo**
   ```bash
   cd /opt
   git clone https://github.com/yourname/woundify.git
   cd woundify
   ```

2. **Setup environment**
   ```bash
   cp .env.example .env
   nano .env  # Edit dengan password yang aman
   ```

   Pastikan:
   ```
   DB_PASSWORD=your_very_secure_password
   GEMINI_API_KEY=your_gemini_key_if_available
   JPA_DDL=validate  # Use 'validate' di production
   ```

3. **Build & start services**
   ```bash
   docker-compose up -d --build
   ```

4. **Verify services running**
   ```bash
   docker-compose ps
   docker-compose logs backend
   docker-compose logs ai-engine
   docker-compose logs postgres
   ```

### C. Setup Domain & SSL (Optional tapi recommended)

Gunakan **Nginx** sebagai reverse proxy + SSL

1. **Install Nginx**
   ```bash
   apt install nginx certbot python3-certbot-nginx -y
   ```

2. **Create Nginx config** di `/etc/nginx/sites-available/woundify`
   ```nginx
   upstream backend {
       server localhost:8080;
   }

   upstream ai_engine {
       server localhost:8000;
   }

   server {
       listen 80;
       server_name your_domain.com;

       # Redirect HTTP to HTTPS
       return 301 https://$server_name$request_uri;
   }

   server {
       listen 443 ssl http2;
       server_name your_domain.com;

       # SSL certificates (setup dengan certbot)
       ssl_certificate /etc/letsencrypt/live/your_domain.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/your_domain.com/privkey.pem;

       location /api {
           proxy_pass http://backend;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }

       location /ai {
           proxy_pass http://ai_engine;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       }

       location / {
           # Serve Flutter web app atau landing page
           root /var/www/woundify;
           index index.html;
           try_files $uri $uri/ /index.html;
       }
   }
   ```

3. **Enable config**
   ```bash
   ln -s /etc/nginx/sites-available/woundify /etc/nginx/sites-enabled/
   nginx -t
   systemctl restart nginx
   ```

4. **Setup SSL certificate**
   ```bash
   certbot certbot --nginx -d your_domain.com
   ```

### D. Auto-restart & Monitoring

1. **Setup auto-restart on reboot**
   ```bash
   docker-compose up -d --build
   # Compose services sudah punya `restart: unless-stopped`
   ```

2. **Monitor logs**
   ```bash
   # Real-time logs
   docker-compose logs -f

   # Specific service
   docker-compose logs -f backend
   ```

3. **Health check**
   ```bash
   # Check all containers running
   docker-compose ps

   # Restart jika ada yang mati
   docker-compose restart backend
   ```

---

## Option 3: Cloud Platform Deployment

### A. Google Cloud Run (Serverless)

Bagus jika traffic tidak konsisten dan mau hemat cost.

1. **Push ke Container Registry**
   ```bash
   gcloud auth configure-docker
   docker tag woundify-backend gcr.io/PROJECT_ID/woundify-backend:latest
   docker push gcr.io/PROJECT_ID/woundify-backend:latest
   ```

2. **Deploy**
   ```bash
   gcloud run deploy woundify-backend \
       --image gcr.io/PROJECT_ID/woundify-backend:latest \
       --platform managed \
       --region us-central1 \
       --set-env-vars SPRING_DATASOURCE_URL=jdbc:postgresql://CLOUD_SQL_IP:5432/woundify
   ```

### B. Railway.app (Paling Praktis)

1. **Push repo ke GitHub**
2. **Go to railway.app** → Connect GitHub
3. **Add services**: PostgreSQL, Backend, AI Engine
4. **Set environment variables** di Railway dashboard
5. **Deploy!** (Automatic dengan setiap push)

### C. Heroku (Deprecated, tapi masih bisa)

Sudah remove free tier, jadi tidak recommended untuk kompetisi gratis.

---

## 📱 Deploy Flutter Mobile App

Mobile app tidak bisa di-host seperti web service. Ada 2 opsi:

### Opsi 1: Build APK untuk Android (Recommended)
```bash
cd woundify-mobile
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```
Share APK file untuk judges download & install.

### Opsi 2: Flutter Web Version
```bash
flutter build web
# Upload ke Firebase Hosting atau any static hosting
firebase deploy
```

---

## 🔍 Testing sebelum kompetisi

### Checklist:

- [ ] Semua containers running without errors
- [ ] Backend accessible di http://server_ip:8080/swagger-ui/index.html
- [ ] AI Engine accessible di http://server_ip:8000/docs
- [ ] Mobile app bisa connect ke backend
- [ ] Database seeding berjalan (credentials: admin@woundify.com / admin)
- [ ] OCR feature bekerja (jika GEMINI_API_KEY tersedia)
- [ ] No warnings dalam logs

### Test commands:

```bash
# Check backend health
curl http://localhost:8080/health

# Check AI engine health
curl http://localhost:8000/docs

# Check database connection
docker-compose exec postgres psql -U woundify -d woundify -c "\dt"

# View all logs
docker-compose logs --tail=100
```

---

## 🚨 Troubleshooting

### Backend tidak konek ke database
```bash
docker-compose logs postgres
docker-compose logs backend

# Solusi: Pastikan postgres healthy
docker-compose down
docker-compose up -d --build
```

### Port conflict
```bash
# Jika port sudah dipake, edit docker-compose.yml:
# ports:
#   - "8080:8080"  -> "8090:8080"  (ubah port kiri)
```

### Out of memory
```bash
# Kurangi RAM untuk services
# Edit docker-compose.yml, tambahkan:
# deploy:
#   resources:
#     limits:
#       memory: 512M
```

### Container keeps restarting
```bash
docker-compose logs backend  # Lihat error message
# Fix error, then:
docker-compose up -d --build
```

---

## 📊 Monitoring & Logs

```bash
# Real-time monitoring
docker stats

# Logs dengan timestamp
docker-compose logs --timestamps

# Follow specific service
docker-compose logs -f backend

# Save logs to file
docker-compose logs > logs_backup.txt
```

---

## 📤 Update deployment saat kompetisi

```bash
# Pull latest changes
git pull origin main

# Rebuild & restart
docker-compose up -d --build

# Verify new version
docker-compose logs backend | grep "Started Application"
```

---

## 💡 Tips untuk Kompetisi:

1. **Backup database sebelum kompetisi**
   ```bash
   docker-compose exec postgres pg_dump -U woundify woundify > backup.sql
   ```

2. **Backup .env file** (jangan commit ke git!)

3. **Siapkan screenshot/metrics** untuk dokumentasi:
   - API response time
   - Database uptime
   - Prediction accuracy

4. **Maintain 2 versions**:
   - Production (stable, untuk judges)
   - Development (untuk testing fixes)

5. **Keep spare VPS ready** (jika tiba-tiba down)

---

## 📞 Support

Untuk error atau masalah:
```bash
# Collect diagnostics
docker-compose ps
docker-compose logs > diagnostics.log
docker stats --no-stream > stats.log

# Then share logs untuk debugging
```
