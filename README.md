# Woundify

Woundify is a starter full-stack prototype for diabetic wound infection analysis.

## What is included
- Spring Boot backend API
- Embedded frontend dashboard served from the backend
- In-memory demo data for patients and lab results
- Rule-based AI prediction for bacterial matching and risk scoring

## Run the app
1. Go to the backend folder.
2. Run `mvn spring-boot:run`
3. Open `http://localhost:8080`

## Demo login
- Username: `clinician@example.com`
- Password: `woundify123`

## API highlights
- `POST /api/auth/login`
- `GET /api/patients`
- `POST /api/patients`
- `POST /api/lab-results`
- `POST /api/ai/analyze`
- `GET /api/dashboard/summary`
