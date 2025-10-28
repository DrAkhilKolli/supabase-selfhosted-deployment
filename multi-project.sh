#!/bin/bash

# Supabase Multi-Project Manager
# This script helps you manage multiple Supabase projects locally

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

function show_help() {
    echo "Supabase Multi-Project Manager"
    echo ""
    echo "Usage: ./multi-project.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start           Start all projects"
    echo "  stop            Stop all projects"
    echo "  restart         Restart all projects"
    echo "  status          Show status of all services"
    echo "  logs [service]  Show logs for all services or specific service"
    echo "  create-data     Create sample data in all projects"
    echo "  help            Show this help message"
    echo ""
    echo "Project URLs:"
    echo "  Project 1: http://localhost:8001/project1/"
    echo "  Project 2: http://localhost:8001/project2/"
    echo "  Project 3: http://localhost:8001/project3/"
    echo ""
    echo "Database Connections:"
    echo "  Project 1: postgresql://postgres:password@localhost:5432/project1_db"
    echo "  Project 2: postgresql://postgres:password@localhost:5433/project2_db"
    echo "  Project 3: postgresql://postgres:password@localhost:5434/project3_db"
}

function start_projects() {
    echo "🚀 Starting all Supabase projects..."
    docker compose -f docker-compose-multi.yml up -d
    echo ""
    echo "✅ All projects started!"
    echo ""
    show_urls
}

function stop_projects() {
    echo "🛑 Stopping all Supabase projects..."
    docker compose -f docker-compose-multi.yml down
    echo "✅ All projects stopped!"
}

function restart_projects() {
    echo "🔄 Restarting all Supabase projects..."
    docker compose -f docker-compose-multi.yml restart
    echo "✅ All projects restarted!"
}

function show_status() {
    echo "📊 Project Status:"
    echo ""
    docker compose -f docker-compose-multi.yml ps
}

function show_logs() {
    if [ -n "$1" ]; then
        echo "📋 Showing logs for $1..."
        docker compose -f docker-compose-multi.yml logs -f "$1"
    else
        echo "📋 Showing logs for all services..."
        docker compose -f docker-compose-multi.yml logs -f
    fi
}

function create_sample_data() {
    echo "📝 Creating sample data in all projects..."
    
    # Wait for databases to be ready
    sleep 5
    
    # Project 1
    echo "Creating data in Project 1..."
    docker exec supabase-db-project1 psql -U postgres -d project1_db -c "
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name TEXT,
            email TEXT,
            project TEXT DEFAULT 'project1',
            created_at TIMESTAMP DEFAULT NOW()
        );
        INSERT INTO users (name, email) VALUES 
        ('Alice Johnson', 'alice@project1.com'),
        ('Bob Smith', 'bob@project1.com')
        ON CONFLICT DO NOTHING;
    "
    
    # Project 2
    echo "Creating data in Project 2..."
    docker exec supabase-db-project2 psql -U postgres -d project2_db -c "
        CREATE TABLE IF NOT EXISTS products (
            id SERIAL PRIMARY KEY,
            name TEXT,
            price DECIMAL(10,2),
            category TEXT DEFAULT 'project2',
            created_at TIMESTAMP DEFAULT NOW()
        );
        INSERT INTO products (name, price) VALUES 
        ('Laptop', 999.99),
        ('Mouse', 29.99)
        ON CONFLICT DO NOTHING;
    "
    
    # Project 3
    echo "Creating data in Project 3..."
    docker exec supabase-db-project3 psql -U postgres -d project3_db -c "
        CREATE TABLE IF NOT EXISTS orders (
            id SERIAL PRIMARY KEY,
            customer_name TEXT,
            total_amount DECIMAL(10,2),
            status TEXT DEFAULT 'pending',
            project TEXT DEFAULT 'project3',
            created_at TIMESTAMP DEFAULT NOW()
        );
        INSERT INTO orders (customer_name, total_amount, status) VALUES 
        ('John Doe', 150.00, 'completed'),
        ('Jane Wilson', 75.50, 'pending')
        ON CONFLICT DO NOTHING;
    "
    
    echo "✅ Sample data created in all projects!"
}

function show_urls() {
    echo "🌐 Project URLs:"
    echo ""
    echo "  📊 Project 1 (Users):"
    echo "    REST API: http://localhost:8001/project1/rest/v1/"
    echo "    Auth API: http://localhost:8001/project1/auth/v1/"
    echo "    Meta API: http://localhost:8001/project1/pg/"
    echo ""
    echo "  🛍️  Project 2 (Products):"
    echo "    REST API: http://localhost:8001/project2/rest/v1/"
    echo ""
    echo "  📦 Project 3 (Orders):"
    echo "    REST API: http://localhost:8001/project3/rest/v1/"
    echo ""
    echo "💡 Example API calls:"
    echo "  curl http://localhost:8001/project1/rest/v1/users -H 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE'"
    echo "  curl http://localhost:8001/project2/rest/v1/products -H 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE'"
    echo "  curl http://localhost:8001/project3/rest/v1/orders -H 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE'"
}

# Main command handling
case "${1:-help}" in
    "start")
        start_projects
        ;;
    "stop")
        stop_projects
        ;;
    "restart")
        restart_projects
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs "$2"
        ;;
    "create-data")
        create_sample_data
        ;;
    "urls")
        show_urls
        ;;
    "help"|*)
        show_help
        ;;
esac