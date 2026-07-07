@echo off
REM Woundify Quick Deploy Script for Windows
REM Usage: deploy.bat [up|down|logs|status|restart|test]

setlocal enabledelayedexpansion

set COMMAND=%1
if "%COMMAND%"=="" set COMMAND=up

echo.
echo 🚀 Woundify Deployment Script (Windows)
echo ================================
echo.

if /i "%COMMAND%"=="up" (
    echo 📦 Starting all services...
    if not exist .env (
        echo ⚠️  .env file not found. Creating from template...
        copy .env.example .env
        echo ✅ .env created. Please edit it with your settings.
        exit /b 1
    )
    docker-compose up -d --build
    echo ✅ Services starting. Waiting for health checks...
    timeout /t 10 /nobreak
    docker-compose ps
    echo.
    echo 📊 Access points:
    echo   - Backend API: http://localhost:8080/swagger-ui/index.html
    echo   - AI Engine: http://localhost:8000/docs
    echo   - Database: localhost:5432
) else if /i "%COMMAND%"=="down" (
    echo 🛑 Stopping all services...
    docker-compose down
    echo ✅ Services stopped
) else if /i "%COMMAND%"=="logs" (
    echo 📋 Showing logs (press Ctrl+C to exit)...
    docker-compose logs -f
) else if /i "%COMMAND%"=="status" (
    echo 📊 Service status:
    docker-compose ps
    echo.
    docker stats --no-stream
) else if /i "%COMMAND%"=="restart" (
    echo 🔄 Restarting services...
    docker-compose restart
    echo ✅ Services restarted
    docker-compose ps
) else if /i "%COMMAND%"=="test" (
    echo 🧪 Running health checks...
    echo Checking Backend...
    for /f %%i in ('docker inspect -f "{{.State.Running}}" woundify-backend 2^>nul') do set backend_running=%%i
    if "!backend_running!"=="true" (
        echo ✅ Backend running
    ) else (
        echo ❌ Backend not running
    )

    echo Checking AI Engine...
    for /f %%i in ('docker inspect -f "{{.State.Running}}" woundify-ai 2^>nul') do set ai_running=%%i
    if "!ai_running!"=="true" (
        echo ✅ AI Engine running
    ) else (
        echo ❌ AI Engine not running
    )

    echo Checking Database...
    for /f %%i in ('docker inspect -f "{{.State.Running}}" woundify-postgres 2^>nul') do set db_running=%%i
    if "!db_running!"=="true" (
        echo ✅ Database running
    ) else (
        echo ❌ Database not running
    )
) else (
    echo Usage: %0 [up^|down^|logs^|status^|restart^|test]
    echo.
    echo Commands:
    echo   up      - Start all services
    echo   down    - Stop all services
    echo   logs    - Show real-time logs
    echo   status  - Show service status
    echo   restart - Restart all services
    echo   test    - Run health checks
    exit /b 1
)

endlocal
