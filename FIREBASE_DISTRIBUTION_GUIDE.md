# 🚀 Firebase App Distribution - Complete Guide

Panduan lengkap untuk distribute APK ke judges via Firebase.

---

## 📋 Prerequisite:

Pastikan sudah ada:
- ✅ Google account (buat kalau belum)
- ✅ Firebase project (akan dibuat di step 1)
- ✅ Node.js installed (untuk Firebase CLI)
- ✅ Flutter app siap (woundify-mobile)

---

## Step 1: Install Firebase CLI (5 menit)

### **1.1 Install Node.js (Jika belum ada)**

Download dari: https://nodejs.org/ (LTS version)

Verify installation:
```bash
node --version
npm --version
```

### **1.2 Install Firebase CLI**

```bash
npm install -g firebase-tools
```

Verify:
```bash
firebase --version
```

Output should be: `firebase-tools/12.x.x`

---

## Step 2: Create Firebase Project (5 menit)

### **2.1 Go to Firebase Console**

Visit: https://console.firebase.google.com/

### **2.2 Create New Project**

Click "Create a project"

```
Project name: Woundify-Competition
Location: Singapore (or closest to you)
Analytics: Disable (optional untuk kompetisi)
```

Click "Create project"

Wait ~2 minutes untuk project creation.

### **2.3 Get Project ID**

After creation:
- Go to Project Settings (gear icon)
- Copy "Project ID"
- Save untuk step selanjutnya

Example: `woundify-competition-a1b2c3`

---

## Step 3: Setup Firebase in Your Flutter Project (10 menit)

### **3.1 Navigate to Mobile App**

```bash
cd C:\Users\zafir\Downloads\woundify\woundify-mobile
```

### **3.2 Initialize Firebase**

```bash
firebase login
# Browser window opens → Sign in with Google account
# Approve permissions
```

### **3.3 Configure Firebase for Flutter**

```bash
flutter pub add firebase_core
flutter pub add firebase_crashlytics  # Optional, for better monitoring
```

### **3.4 Install FlutterFire CLI** (Recommended)

```bash
dart pub global activate flutterfire_cli
```

### **3.5 Configure FlutterFire**

```bash
flutterfire configure
# Select: Android (tekan space)
# Select your Firebase project: Woundify-Competition
# Answer: Use google-services.json (Y)
```

Ini akan auto-generate `google-services.json` file.

### **3.6 Update main.dart** (Optional untuk crash reporting)

Di `lib/main.dart`, tambahkan:

```dart
import 'firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

---

## Step 4: Create Release Signing Key (5 menit)

Diperlukan untuk sign APK dengan release key.

### **4.1 Generate Key**

```bash
cd woundify-mobile/android/app

# Windows:
keytool -genkey -v -keystore release.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias woundify-key

# Mac/Linux:
keytool -genkey -v -keystore release.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias woundify-key
```

**Answer prompts:**
```
Keystore password: your_secure_password  (REMEMBER THIS!)
Re-enter password: your_secure_password

First and last name: Woundify App
Organizational unit: Development
Organization: Woundify
City: Singapore
State/Province: SG
Country code: SG
Is CN correct? yes

Key password: [press Enter = same as keystore]
```

Output:
```
Keystore saved at: release.keystore
```

### **4.2 Configure Gradle untuk Sign APK**

Edit `android/app/build.gradle`:

```gradle
// Tambahkan sebelum android {}:
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...
    
    // Tambahkan ini:
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### **4.3 Create key.properties File**

Di `android/key.properties`:

```properties
storePassword=your_secure_password
keyPassword=your_secure_password
keyAlias=woundify-key
storeFile=app/release.keystore
```

**⚠️ IMPORTANT:** Add to `.gitignore`:
```
android/key.properties
android/app/release.keystore
```

(Don't commit keystore file!)

---

## Step 5: Build Release APK (5-10 menit)

```bash
cd C:\Users\zafir\Downloads\woundify\woundify-mobile

flutter clean
flutter pub get
flutter build apk --release
```

**Output:**
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (35.5MB).
```

File location:
```
woundify-mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

## Step 6: Setup Firebase App Distribution (5 menit)

### **6.1 Go to Firebase Console**

https://console.firebase.google.com/ → Woundify-Competition project

### **6.2 Find App Distribution**

Left menu → "App Distribution" (atau build → App Distribution)

### **6.3 Register Android App**

Click "Get started"

```
App ID: com.woundify.mobile  (or your package name)
Display name: Woundify Competition
```

Click "Register app"

### **6.4 Download google-services.json**

Firebase akan offer untuk download, tapi kita sudah auto-generate di step 3.

---

## Step 7: Get App ID for Firebase CLI (2 menit)

### **7.1 Find Android App ID**

In Firebase Console:
- Project Settings (gear icon)
- Your apps → Android app
- Copy the "App ID"

Example: `1:123456789:android:abcdef1234567890`

Save this! Kita perlu untuk command nanti.

---

## Step 8: Upload APK to Firebase (2 menit)

### **8.1 Go to App Distribution**

Firebase Console → App Distribution

### **8.2 Upload APK**

```bash
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app=YOUR_APP_ID \
  --release-notes="Competition Build v1.0 - Ready for testing" \
  --testers="judge1@gmail.com,judge2@gmail.com,judge3@gmail.com"
```

Replace:
- `YOUR_APP_ID` dengan app ID dari step 7
- `judge1@gmail.com` dll dengan actual judge emails

Atau, bisa copy-paste dari Firebase Console → "Distribute" button

### **8.3 Wait for Upload**

```
Uploading APK... 100%
Sending invitations...
```

Takes ~1-2 minutes.

Success message:
```
✓ Successfully distributed app
✓ Invitations sent to testers
```

---

## Step 9: Judges Receive & Install (Judges' side)

### **9.1 Judges Get Email**

From: `noreply@firebase.google.com`

Subject: `Woundify Competition` is ready for testing

### **9.2 Judges Click Link**

- Open email
- Click "Try it on Google Play"
- Or direct link: Shows in email

### **9.3 Install on Device**

- Opens Google Play
- Click "Install"
- App downloads & installs automatically
- Takes ~1-2 minutes

### **9.4 Judges Open & Test**

- Tap app icon
- Login dengan: admin@woundify.com / admin
- Start testing!

---

## 🔄 Update App (If Bug Fix Needed)

Jika ada bug yang harus di-fix:

```bash
# 1. Fix code
# 2. Build new APK
flutter build apk --release

# 3. Upload new version
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app=YOUR_APP_ID \
  --release-notes="v1.1 - Fixed login issue"
```

Judges akan notified ada update, auto-download & install.

---

## 🎯 Quick Reference Commands

### **Login**
```bash
firebase login
```

### **List projects**
```bash
firebase projects:list
```

### **Use specific project**
```bash
firebase use woundify-competition-a1b2c3
```

### **Distribute APK**
```bash
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app=1:123456789:android:abc123 \
  --release-notes="v1.0 Competition Build" \
  --testers="judge1@gmail.com,judge2@gmail.com"
```

### **Add new testers**
```bash
firebase appdistribution:testers:add judge4@gmail.com --app=YOUR_APP_ID
```

---

## 🚨 Troubleshooting

### **Problem: "Command not found: firebase"**

**Solution:**
```bash
npm install -g firebase-tools
firebase --version
```

### **Problem: "Authentication required"**

**Solution:**
```bash
firebase logout
firebase login
```

### **Problem: "App ID not found"**

**Solution:**
1. Go to Firebase Console
2. Project Settings → Your apps
3. Copy correct App ID
4. Use in command

### **Problem: "APK upload failed"**

**Check:**
1. APK file exists: `build/app/outputs/flutter-apk/app-release.apk`
2. App ID correct
3. Firebase project accessible
4. Internet connection stable

**Fix:**
```bash
flutter clean
flutter pub get
flutter build apk --release
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk --app=YOUR_APP_ID
```

### **Problem: "Judges not receiving email"**

**Check:**
1. Email address spelled correctly
2. Check spam/promotions folder
3. Wait 5-10 minutes
4. Ask judges to check inbox

**Re-send invitations:**
```bash
firebase appdistribution:testers:add judge@gmail.com --app=YOUR_APP_ID
```

### **Problem: "App won't install on judge's device"**

**Check:**
1. Device Android version >= 5.0 (Android SDK 21+)
2. Enough storage (app size ~35MB)
3. Device allow "unknown sources"

**Solution for judge:**
- Settings → Apps → Special app access → "Install unknown apps" → Allow Google Play

---

## 📋 Pre-Competition Checklist

- [ ] Firebase project created
- [ ] Firebase CLI installed
- [ ] Release keystore created
- [ ] key.properties configured
- [ ] APK built successfully
- [ ] App ID obtained from Firebase
- [ ] APK uploaded to Firebase
- [ ] Test judges added (at least 2)
- [ ] Received email confirmation
- [ ] Tested installation on device
- [ ] Tested app login & workflow

---

## 📊 Timeline

```
Today:
  Step 1-2: Setup Firebase         (10 min)
  Step 3-4: Flutter config          (15 min)
  Step 5: Build APK                 (10 min)
  Step 6-7: Firebase setup          (10 min)
  Step 8: Upload & distribute       (5 min)
  ─────────────────────────────────
  TOTAL: ~50 minutes

Tomorrow:
  Judges get email
  Judges install app
  Judges test & provide feedback

```

---

## 💡 Tips & Best Practices

### **1. Test Locally First**
```bash
flutter run
# Test app thoroughly before distributing
```

### **2. Clear Release Notes**
```
Bad: "v1.0"
Good: "v1.0 - Initial release for competition. Features: patient management, lab data input, predictions"
```

### **3. Multiple Rounds**
```
v1.0 - Initial release (Oct 1)
v1.1 - Bug fixes (Oct 5)
v1.2 - Performance improvement (Oct 10)
```

Judges automatically get updates!

### **4. Monitor Feedback**
Firebase App Distribution shows:
- Number of installations
- Crash reports
- User feedback

Check regularly!

---

## 🎉 Success Indicators

✅ **Email sent to judges** - They receive invitation
✅ **App installed** - Firebase shows installations
✅ **Can login** - Judge connects to backend
✅ **Can test** - Full workflow works
✅ **No crashes** - App stable

---

## 🔐 Security Notes

**Don't commit to Git:**
- `android/key.properties`
- `android/app/release.keystore`
- Firebase credentials

Already in `.gitignore`? Check!

```bash
git status
# Should NOT show key files
```

---

## 📞 Reference Links

- Firebase Console: https://console.firebase.google.com/
- Firebase CLI Docs: https://firebase.google.com/docs/cli
- Flutter Firebase: https://firebase.flutter.dev/
- App Distribution: https://firebase.google.com/docs/app-distribution

---

## 🚀 Next Step

After uploading to Firebase:

1. Share judges' email list
2. Upload APK
3. Wait for confirmation emails to judges
4. Judges install & test
5. Collect feedback
6. Fix bugs if needed
7. Re-upload new version

**Done! Now judges can test your app 24/7 from their devices!** 🎉

---

## ⚡ Quick Start (TL;DR)

```bash
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Login
firebase login

# 3. Setup Flutter
cd woundify-mobile
flutterfire configure

# 4. Create signing key
cd android/app
keytool -genkey -v -keystore release.keystore ...

# 5. Build APK
cd ../..
flutter build apk --release

# 6. Upload to Firebase
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app=YOUR_APP_ID \
  --testers="judge1@gmail.com,judge2@gmail.com"

# 7. Done! Judges receive email & install app
```

**Total time: ~1 hour**

---

**Questions? Check troubleshooting section atau Firebase docs!** 📚

Happy distributing! 🚀
