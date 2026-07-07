#!/bin/bash

# Woundify Quick Deploy Script
# Usage: ./deploy.sh [up|down|logs|status|restart]

set -e

COMMAND=${1:-up}

echo "🚀 Woundify Deployment Script"
echo "================================"

case $COMMAND in
  up)
    echo "📦 Starting all services..."
    if [ ! -f .env ]; then
      echo "⚠️  .env file not found. Creating from template..."
      cp .env.example .env
      echo "✅ .env created. Please edit it with your settings."
      exit 1
    fi
    docker-compose up -d --build
    echo "✅ Services starting. Waiting for health checks..."
    sleep 10
    docker-compose ps
    echo ""
    echo "📊 Access points:"
    echo "  - Backend API: http://localhost:8080/swagger-ui/index.html"
    echo "  - AI Engine: http://localhost:8000/docs"
    echo "  - Database: localhost:5432"
    ;;

  down)
    echo "🛑 Stopping all services..."
    docker-compose down
    echo "✅ Services stopped"
    ;;

  logs)
    echo "📋 Showing logs (press Ctrl+C to exit)..."
    docker-compose logs -f
    ;;

  status)
    echo "📊 Service status:"
    docker-compose ps
    echo ""
    docker stats --no-stream
    ;;

  restart)
    echo "🔄 Restarting services..."
    docker-compose restart
    echo "✅ Services restarted"
    docker-compose ps
    ;;

  test)
    echo "🧪 Running health checks..."
    echo "Checking Backend..."
    curl -s http://localhost:8080/health || echo "❌ Backend not responding"
    echo ""
    echo "Checking AI Engine..."
    curl -s http://localhost:8000/docs || echo "❌ AI Engine not responding"
    echo ""
    echo "Checking Database..."
    docker-compose exec -T postgres pg_isready -U woundify || echo "❌ Database not responding"
    ;;

  *)
    echo "Usage: $0 [up|down|logs|status|restart|test]"
    echo ""
    echo "Commands:"
    echo "  up      - Start all services"
    echo "  down    - Stop all services"
    echo "  logs    - Show real-time logs"
    echo "  status  - Show service status"
    echo "  restart - Restart all services"
    echo "  test    - Run health checks"
    exit 1
    ;;
esac
