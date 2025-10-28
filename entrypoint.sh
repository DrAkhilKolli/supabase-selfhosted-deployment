#!/bin/bash
# Entrypoint script for Supabase container

set -e

echo "🚀 Starting Supabase Self-Hosted Container..."

# Generate environment file if not exists
if [ ! -f .env ]; then
    echo "📝 Generating .env file from template..."
    cp .env.template .env
    
    # Generate secure secrets
    echo "🔐 Generating secure secrets..."
    
    # Generate JWT secret
    JWT_SECRET=$(openssl rand -base64 32)
    sed -i "s/YOUR_JWT_SECRET_HERE/$JWT_SECRET/g" .env
    
    # Generate database password
    DB_PASSWORD=$(openssl rand -base64 16)
    sed -i "s/YOUR_POSTGRES_PASSWORD_HERE/$DB_PASSWORD/g" .env
    
    # Generate Anon key (using JWT secret)
    ANON_KEY=$(echo '{"role":"anon","iss":"supabase"}' | openssl dgst -sha256 -hmac "$JWT_SECRET" -binary | base64)
    sed -i "s/YOUR_ANON_KEY_HERE/$ANON_KEY/g" .env
    
    # Generate Service Role key
    SERVICE_ROLE_KEY=$(echo '{"role":"service_role","iss":"supabase"}' | openssl dgst -sha256 -hmac "$JWT_SECRET" -binary | base64)
    sed -i "s/YOUR_SERVICE_ROLE_KEY_HERE/$SERVICE_ROLE_KEY/g" .env
    
    echo "✅ Environment configured successfully"
fi

# Ensure Docker daemon is available
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker daemon not available. Starting Docker..."
    dockerd-entrypoint.sh &
    sleep 10
fi

# Initialize database if needed
if [ ! -d "volumes/db/data" ]; then
    echo "🗄️ Initializing database volumes..."
    mkdir -p volumes/db/data
fi

echo "🎯 Starting Supabase services..."

# Execute the command
exec "$@"