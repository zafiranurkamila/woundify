# ⚡ Quick Start - Deploy Woundify untuk Kompetisi

## 🎯 Apa yang sudah dibuat:

```
woundify/
├── docker-compose.yml       ← Main orchestration file
├── .env.example             ← Template untuk production config
├── DEPLOYMENT.md            ← Detailed deployment guide
├── deploy.sh                ← Quick deploy script
├── woundify-backend/
│   ├── Dockerfile           ← Container untuk Spring Boot
│   └── src/main/resources/
│       └── application.properties ← Updated dengan env vars
├── woundify-ai/
│   └── Dockerfile           ← Container untuk Python FastAPI
└── woundify-mobile/
    └── pubspec.yaml         ← Flutter mobile app
```

---

## 🚀 Cara Deploy Cepat:

### **STEP 1: Setup Lokal (Testing)**

```bash
# 1. Navigate ke project root
cd woundify

# 2. Buat .env file
cp .env.example .env

# 3. Edit .env jika perlu (tapi untuk testing bisa langsung)
nano .env

# 4. Start semua service
docker-compose up -d --build

# 5. Check status
docker-compose ps

# 6. Test endpoints
# - Backend: http://localhost:8080/swagger-ui/index.html
# - AI Engine: http://localhost:8000/docs
# - Login: admin@woundify.com / admin
```

### **STEP 2: Deploy ke VPS (24/7 Running)**

```bash
# 1. SSH ke VPS
ssh root@your_vps_ip

# 2. Install Docker (first time only)
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh

# 3. Clone project
cd /opt && git clone https://github.com/yourname/woundify.git && cd woundify

# 4. Setup environment
cp .env.example .env
nano .env  # Edit dengan password yang aman

# 5. Deploy
docker-compose up -d --build

# 6. Verify
docker-compose ps

# 7. Check logs
docker-compose logs
```

### **STEP 3: Setup Domain (Optional tapi recommended)**

Follow "Option 3: Setup Domain & SSL" di `DEPLOYMENT.md`

---

## 📊 Service Architecture:

```
┌─────────────────────────────────────────────────┐
│          Mobile App (Flutter)                   │
│  Built as APK or Web (hosted separately)        │
└────────────────────┬────────────────────────────┘
                     │ HTTP/REST API
                     ↓
┌─────────────────────────────────────────────────┐
│    Nginx (Optional - Reverse Proxy)             │
│    (Setup untuk production dengan domain)       │
└────────────────────┬────────────────────────────┘
                     │
      ┌──────────────┴──────────────┐
      ↓                             ↓
┌──────────────────┐        ┌──────────────────┐
│ Spring Boot      │        │ Python FastAPI   │
│ Backend          │        │ AI Engine        │
│ :8080            │        │ :8000            │
│                  │        │                  │
│ - Auth (JWT)     │        │ - ML Model       │
│ - Patient CRUD   │        │ - OCR (Gemini)   │
│ - Epidemiology   │        │ - Statistics     │
└────────┬─────────┘        └──────────────────┘
         │
         └──────────────┬────────────────────┐
                        ↓
                  ┌──────────────────┐
                  │  PostgreSQL      │
                  │  Database        │
                  │ :5432            │
                  └──────────────────┘
```

---

## 🔧 Common Commands:

```bash
# Start services
docker-compose up -d --build

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# View status
docker-compose ps

# Restart specific service
docker-compose restart backend

# Execute command in container
docker-compose exec backend bash

# Backup database
docker-compose exec postgres pg_dump -U woundify woundify > backup.sql
```

---

## 🔍 Important Configuration:

### `.env` file (Create from `.env.example`)

```ini
# Database credentials
DB_NAME=woundify
DB_USER=woundify
DB_PASSWORD=YOUR_SECURE_PASSWORD    # Change this!

# Gemini API (optional untuk OCR feature)
GEMINI_API_KEY=your_key_here

# Hibernate schema management
JPA_DDL=update        # For dev/testing
# JPA_DDL=validate    # For production
```

### Environment Variables:

| Variable | Purpose | Default | Docker Value |
|----------|---------|---------|--------------|
| `DB_NAME` | Database name | woundify | woundify |
| `DB_USER` | Database user | woundify | woundify |
| `DB_PASSWORD` | Database password | woundify | **CHANGE IN .env** |
| `GEMINI_API_KEY` | Google Gemini API | (empty) | (empty) |
| `JPA_DDL` | Hibernate migration | update | update |
| `SERVER_PORT` | Backend port | 8080 | 8080 |

---

## 🧪 Health Checks:

```bash
# Check if all containers are running
docker-compose ps

# Check specific service logs
docker-compose logs backend     # Backend logs
docker-compose logs ai-engine   # AI Engine logs
docker-compose logs postgres    # Database logs

# Test API endpoints
curl http://localhost:8080/health
curl http://localhost:8000/docs

# Check database connection
docker-compose exec postgres psql -U woundify -d woundify -c "SELECT 1"
```

---

## 🚨 Troubleshooting Quick Fixes:

| Problem | Solution |
|---------|----------|
| Containers not starting | `docker-compose logs` to see errors |
| Port already in use | Change port in docker-compose.yml |
| Database connection error | Wait 10-15s, containers take time to start |
| Out of memory | Check `docker stats`, reduce container limits |
| Backend can't find AI engine | AI engine should start first (dependency: ai-engine) |

---

## 📱 Build Flutter Mobile App for Judges:

```bash
cd woundify-mobile

# Build APK for Android
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Or build for Web
flutter build web
# Output: build/web/

# Configure mobile app to connect to VPS:
# Edit: lib/api_service.dart
# Change: http://localhost:8080 → http://your_vps_ip:8080
```

---

## 📋 Pre-Competition Checklist:

- [ ] All containers running (`docker-compose ps`)
- [ ] Backend accessible (`curl http://localhost:8080/swagger-ui`)
- [ ] AI engine running (`curl http://localhost:8000/docs`)
- [ ] Database populated (login with admin@woundify.com / admin)
- [ ] Mobile app built and tested
- [ ] `.env` file configured with secure passwords
- [ ] VPS deployed and tested (if applicable)
- [ ] Domain/DNS configured (if applicable)
- [ ] Backup of database created
- [ ] Monitoring/logs checked for errors

---

## 📞 Need Help?

1. Check `DEPLOYMENT.md` untuk detailed guide
2. Run `docker-compose logs` untuk error messages
3. Check system resources: `docker stats`
4. Review docker-compose.yml untuk service dependencies

---

## 🎉 Success Indicators:

✅ **Backend running:**
```
curl http://localhost:8080/swagger-ui/index.html
# Should show Swagger UI
```

✅ **AI Engine running:**
```
curl http://localhost:8000/docs
# Should show FastAPI docs
```

✅ **Database healthy:**
```
docker-compose exec postgres psql -U woundify -d woundify -c "\dt"
# Should show tables: users, patients, predictions, etc.
```

✅ **Mobile app connecting:**
- Login dengan admin@woundify.com / admin
- Bisa submit patient data
- Bisa trigger prediction

---

**Good luck di kompetisi! 🏆**
