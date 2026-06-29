# Woundify: Full Stack Clinical Microbiology & AI Risk Monitor

Woundify is an innovative mobile digital health application designed to assist healthcare professionals in identifying bacteria and assessing risks in diabetic wounds (diabetic wound infection). By integrating clinical microbiology, Google Gemini Vision OCR, and machine learning, it speeds up diagnostic decisions and maps regional epidemiological outbreaks.

## System Architecture

1. **Mobile Frontend (Flutter):** Provides patient log registers, manual biochemical inputs, OCR scanning options, and analysis result cards.
2. **Backend API (Spring Boot):** Manages user sessions (JWT), stores patient files, triggers AI predictions, and stores epidemiological profiles.
3. **AI & Statistics Engine (Python FastAPI):** Implements RandomForest bacteria classification, clinical risk inference, OCR processing (Gemini), and statistical calculators (normality, regression, Cronbach's Alpha).
4. **Database (PostgreSQL):** Relational storage mapping entities.

---

## 1. Prerequisites
- **Java 21 JDK** installed.
- **Maven** installed.
- **Python 3.10+** installed.
- **Flutter SDK** (v3.0.0+) installed.
- **PostgreSQL** running locally on port 5432.

---

## 2. Configuration & Running

### A. Database Setup
1. Create a PostgreSQL database named `woundify`:
   ```sql
   CREATE DATABASE woundify;
   ```
2. By default, the backend connects using username `woundify` and password `woundify`. You can customize these variables in `woundify-backend/src/main/resources/application.properties`:
   ```properties
   spring.datasource.url=jdbc:postgresql://localhost:5432/woundify
   spring.datasource.username=your_username
   spring.datasource.password=your_password
   ```

### B. Running the Python AI Engine
1. Navigate to the `woundify-ai` folder:
   ```bash
   cd woundify-ai
   ```
2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   # On Windows:
   venv\Scripts\activate
   # On Linux/macOS:
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. (Optional) Set your Gemini API Key for OCR vision support:
   ```bash
   # On Windows:
   set GEMINI_API_KEY=your_gemini_api_key_here
   # On Linux/macOS:
   export GEMINI_API_KEY="your_gemini_api_key_here"
   ```
   *Note: If no API key is set, the service falls back to a deterministic rule-based mock parser.*
5. Run the FastAPI server:
   ```bash
   python main.py
   ```
   The engine starts at `http://localhost:8000`. You can inspect the Swagger documentation at `http://localhost:8000/docs`.

### C. Running the Spring Boot Backend
1. Navigate to the `woundify-backend` folder:
   ```bash
   cd woundify-backend
   ```
2. Ensure Python service is running, then start the Spring Boot app:
   ```bash
   mvn spring-boot:run
   ```
   The backend starts at `http://localhost:8080`.
   - On startup, the `DatabaseSeeder` automatically populates reference bacterial strains and mock epidemiology reports.
   - Swagger APIs can be accessed at `http://localhost:8080/swagger-ui/index.html` (if configured) or standard REST paths.

### D. Running the Flutter Mobile App
1. Navigate to the `woundify-mobile` folder:
   ```bash
   cd woundify-mobile
   ```
2. Retrieve packages:
   ```bash
   flutter pub get
   ```
3. Launch the app (or run on simulator):
   ```bash
   flutter run
   ```
   *Note: To connect from an Android Emulator or iOS Simulator to localhost, adjust `baseUrl` in `lib/api_service.dart` (e.g., use `http://10.0.2.2:8080` for Android emulator).*

---

## 3. Seed Credentials (Auth)
To sign in to the application, use the default seeded credentials:
- **Email:** `admin@woundify.com`
- **Password:** `admin` (or register a new user using the `/api/auth/register` API).
