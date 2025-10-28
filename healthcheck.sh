#!/bin/bash
# Health check script for Supabase services

set -e

# Check if main services are running
echo "🏥 Checking Supabase services health..."

# Check Supabase Studio (port 8000)
if curl -f http://localhost:8000/api/health >/dev/null 2>&1; then
    echo "✅ Supabase Studio: Healthy"
else
    echo "❌ Supabase Studio: Unhealthy"
    exit 1
fi

# Check PostgreSQL (port 5432)
if nc -z localhost 5432; then
    echo "✅ PostgreSQL: Healthy"
else
    echo "❌ PostgreSQL: Unhealthy"
    exit 1
fi

# Check Auth service (port 9999)
if curl -f http://localhost:9999/health >/dev/null 2>&1; then
    echo "✅ Auth Service: Healthy"
else
    echo "❌ Auth Service: Unhealthy"
    exit 1
fi

echo "🎉 All services healthy!"
exit 0