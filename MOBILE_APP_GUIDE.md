# 📱 Woundify Mobile App - Complete Guide

## 🎯 3 Cara untuk Run Mobile App:

### **Option 1: Run di Android Emulator (Testing Lokal)**
### **Option 2: Run di Physical Android Device**
### **Option 3: Build APK untuk Judges (Distribution)**

---

## 📋 Prerequisite:

Sebelum mulai, pastikan sudah install:

```bash
# 1. Flutter SDK
flutter --version  # Harus >= 3.0.0

# 2. Android SDK & Emulator (untuk Option 1 & 2)
flutter doctor  # Check semua requirement

# 3. Backend services running (lokal atau VPS)
docker-compose ps  # Pastikan backend & database up
```

Jika belum install Flutter:
- Download: https://flutter.dev/docs/get-started/install
- Follow official guide untuk OS kamu

---

## 🚀 OPTION 1: Run di Android Emulator (Rekomendasi untuk Testing)

### **Step 1: Buka Android Emulator**

```bash
# Jika pakai Android Studio:
# Buka AVD Manager → Launch emulator

# Atau via command line:
emulator -avd Pixel_5_API_31  # Adjust nama sesuai setup kamu
```

Wait sampai emulator fully loaded (ada home screen)

### **Step 2: Setup Backend Connection**

Di laptop kamu, backend jalan di `http://localhost:8080`

Tapi Android Emulator **tidak bisa akses localhost langsung**.

Edit `lib/api_service.dart`:

```dart
// Line 8, ubah dari:
static const String baseUrl = 'http://10.36.51.174:8080';

// Menjadi:
static const String baseUrl = 'http://10.0.2.2:8080';  // Magic IP untuk Android Emulator
```

**Why `10.0.2.2`?**
- Android Emulator interprets `10.0.2.2` as the host machine's `localhost`
- Ini special IP yang hanya valid di emulator

### **Step 3: Run Flutter App**

```bash
cd woundify-mobile
flutter pub get          # Install dependencies
flutter run -v           # Run dengan verbose logging
```

Tunggu 1-2 menit sampai app selesai build & load di emulator.

**Success jika:**
```
✓ Built build/app/intermediates/flutter/release/app.apk (32.5MB).
Flutter run key commands.
r                    Hot reload. 🔥🔥🔥
R                    Hot restart.
h                    Help, character input menu, profiling options.
d                    Detach (terminate "flutter run").
```

### **Step 4: Test App**

Login screen harusnya muncul. Try login:
```
Email: admin@woundify.com
Password: admin
```

Jika login berhasil → app connect ke backend dengan baik! ✅

---

## 📱 OPTION 2: Run di Physical Android Device

### **Step 1: Siapkan Physical Device**

1. **Enable Developer Mode:**
   - Buka Settings → About Phone
   - Tap "Build Number" 7x
   - Back → Developer Options
   - Enable "USB Debugging"

2. **Connect ke Laptop via USB**
   - Plug in kabel USB
   - Device akan ask untuk allow USB Debugging
   - Tap "Allow"

### **Step 2: Verify Connection**

```bash
flutter devices
# Harus melihat device kamu listed
```

Output contoh:
```
2 connected devices:

XXXXXXXXXXXXXXXX         • 10.36.51.174          • android • Android 12.0.0
emulator-5554            • emulator-5554          • android • Android API 31
```

### **Step 3: Setup Backend Connection (PENTING!)**

**Scenario A: Backend jalan lokal di laptop**
```dart
// Edit lib/api_service.dart
static const String baseUrl = 'http://your_laptop_ip:8080';
// Contoh: http://192.168.1.100:8080
```

Cari IP laptop kamu:
```bash
# Windows
ipconfig  # Lihat IPv4 Address

# Mac/Linux
ifconfig  # Lihat inet address
```

**Scenario B: Backend jalan di VPS**
```dart
// Edit lib/api_service.dart
static const String baseUrl = 'http://your_vps_ip:8080';
// Atau jika punya domain:
static const String baseUrl = 'https://your_domain.com';
```

### **Step 4: Run Flutter App**

```bash
cd woundify-mobile
flutter pub get
flutter run -v  # Or just: flutter run
```

Tunggu build selesai (first build bisa 2-3 menit).

### **Step 5: Test App**

App harusnya automatically launch di physical device.

Login dengan:
```
Email: admin@woundify.com
Password: admin
```

**Jika berhasil login:**
- App terhubung ke backend ✅
- Kamu bisa:
  - Add patient
  - Input lab data
  - Submit prediction
  - View results

---

## 📦 OPTION 3: Build APK untuk Judges (Distribution)

APK adalah file Android app yang bisa di-install di device manapun.

### **Step 1: Update Backend URL**

Edit `lib/api_service.dart` dengan VPS/domain URL:

```dart
static const String baseUrl = 'http://your_vps_ip:8080';
// Atau:
static const String baseUrl = 'https://your_domain.com';  // Production
```

### **Step 2: Build Release APK**

```bash
cd woundify-mobile

# Build APK (single architecture, faster)
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Atau build untuk multiple architectures:**
```bash
# Build universal APK (supports all Android devices)
flutter build apk --release --split-per-abi
```

### **Step 3: Find APK File**

```
woundify-mobile/
└── build/
    └── app/
        └── outputs/
            └── flutter-apk/
                ├── app-release.apk          ← Single architecture
                ├── app-armeabi-v7a-release.apk    ← 32-bit
                └── app-arm64-v8a-release.apk      ← 64-bit
```

### **Step 4: Distribute to Judges**

**Method A: Direct File**
- Email atau USB: `app-release.apk` (atau app-arm64-v8a-release.apk untuk 64-bit devices)
- Judges install: buka file → Install

**Method B: Firebase App Distribution**
```bash
# Setup Firebase (one time)
firebase login
firebase init

# Upload APK
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app=YOUR_APP_ID \
  --release-notes="Competition Build v1.0" \
  --testers="judge1@example.com,judge2@example.com"
```

**Method C: Google Play Store** (jika ada time)
1. Create signing key
2. Upload ke Play Store
3. Share link ke judges

---

## 🔧 Troubleshooting Mobile App:

### **Problem: App won't connect to backend**

**Error:** "Login failed: Connection refused"

**Solutions:**

1. **Check backend is running:**
   ```bash
   docker-compose ps  # All should be "Up"
   curl http://localhost:8080/swagger-ui/index.html
   ```

2. **Check baseUrl in api_service.dart:**
   - Emulator: `http://10.0.2.2:8080`
   - Physical device: `http://your_laptop_ip:8080` atau `http://your_vps_ip:8080`
   - VPS: `http://your_vps_domain:8080`

3. **Check network connectivity:**
   ```bash
   # From device, ping backend
   ping 10.0.2.2  (emulator)
   ping your_laptop_ip  (physical)
   ```

### **Problem: Emulator too slow**

**Solutions:**
- Use physical device instead (faster)
- Increase emulator RAM: AVD Manager → Edit → RAM allocation
- Close other apps

### **Problem: "Flutter not found"**

**Solution:**
```bash
flutter --version  # Check if Flutter in PATH

# If not found, add Flutter to PATH:
# Windows: Edit Environment Variables
# Add: C:\path\to\flutter\bin
# Mac/Linux: Add to ~/.bashrc or ~/.zshrc:
# export PATH="$PATH:$HOME/flutter/bin"
```

### **Problem: Build fails with permission error**

**Solution:**
```bash
cd woundify-mobile
flutter clean
flutter pub get
flutter run
```

### **Problem: "Gradle build failed"**

**Solution:**
```bash
cd woundify-mobile
flutter clean
flutter pub get
./gradlew clean  # Clear Gradle cache
flutter run
```

---

## 📱 App Screens Overview:

### **1. Login Screen**
- Email: `admin@woundify.com`
- Password: `admin`

### **2. Home Screen**
- List of patients
- "Add Patient" button
- Navigation menu

### **3. Patient Form Screen**
- Input patient name, age, diabetes type
- Save patient

### **4. Lab Input Screen**
- Input bacterial characteristics:
  - Gram stain (+ or -)
  - Shape (coccus or bacillus)
  - IMVIC tests
  - Other culture results
- Submit untuk prediction

### **5. Prediction Result Screen**
- Show predicted bacteria species
- Risk assessment
- Recommendation for treatment
- Save/Export hasil

### **6. Patient Detail Screen**
- View patient info
- View history of predictions
- Edit patient data

### **7. Doctor Referral Inbox**
- View referrals (doctor-specific)
- Status tracking

### **8. Epidemiology Trends Screen**
- Regional bacterial patterns
- Statistics

---

## 🎨 UI/UX Features:

✅ Material Design 3 (modern UI)
✅ Responsive layout (works on different screen sizes)
✅ Dark/Light mode support
✅ Offline data caching (local storage)
✅ PDF report export
✅ Image picker untuk sample photos

---

## 🚀 Dev Tips:

### **Hot Reload (develop faster)**
```bash
# While running:
r  # Hot reload (refresh UI, keep state)
R  # Hot restart (restart app)
```

### **Debug Mode**
```bash
flutter run
# Then press 'd' untuk debug menu
```

### **View Logs**
```bash
# Terminal 1: Run app
flutter run

# Terminal 2: View logs
flutter logs
```

### **Profile Mode** (check performance)
```bash
flutter run --profile
```

---

## 📊 Configuration Reference:

### **lib/api_service.dart** - Backend connection settings

```dart
// Change this line for different environments:
static const String baseUrl = 'http://10.0.2.2:8080';  // Emulator
static const String baseUrl = 'http://192.168.1.100:8080';  // Physical (local)
static const String baseUrl = 'http://64.23.241.50:8080';  // Physical (VPS)
static const String baseUrl = 'https://woundify.example.com';  // Production
```

---

## ✅ Checklist sebelum Deploy:

- [ ] Backend services running
- [ ] Test app in Android Emulator first
- [ ] Update baseUrl to VPS/domain IP
- [ ] Test on physical Android device
- [ ] Can login with admin credentials
- [ ] Can add patient & submit prediction
- [ ] Build release APK: `flutter build apk --release`
- [ ] APK tested on multiple devices (if possible)
- [ ] Share APK dengan judges

---

## 📲 For Judges:

### **Installation:**
1. Download `app-release.apk` file
2. Connect Android phone to computer
3. `adb install app-release.apk`
   - Or: Copy file → Open on phone → Install

### **Usage:**
1. Open app
2. Login: `admin@woundify.com` / `admin`
3. Navigate to "Add Patient" atau select existing patient
4. Input lab data
5. Tap "Predict" untuk submit
6. View prediction results

---

## 🔐 Security Notes:

- Default credentials (`admin@woundify.com / admin`) untuk testing only
- Change password di production
- App supports JWT token auth
- No credentials hardcoded in APK
- Sensitive data stored in local secure storage

---

## 📞 Need Help?

- Check Flutter docs: https://flutter.dev/docs
- Check api_service.dart untuk API endpoints
- Check QUICK_START.md untuk backend setup

---

**Happy testing! 📱✨**

