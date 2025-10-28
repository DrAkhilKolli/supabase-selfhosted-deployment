#!/bin/bash

# Multi-Project Setup Script
# This creates multiple projects within a single Supabase instance using separate schemas

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "🚀 Setting up Multi-Project Supabase Environment..."

# Start the main Supabase instance
echo "📦 Starting main Supabase services..."
docker compose up -d

echo "⏳ Waiting for database to be ready..."
sleep 20

# Create additional projects as separate schemas
echo "🏗️  Creating Project Schemas..."

# Project 1: Users Management
echo "Creating Project 1: Users Management..."
docker exec supabase-db psql -U postgres -d postgres -c "
-- Create project1 schema
CREATE SCHEMA IF NOT EXISTS project1;

-- Set search path for this session
SET search_path TO project1, public;

-- Create users table
CREATE TABLE IF NOT EXISTS project1.users (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT DEFAULT 'user',
    project TEXT DEFAULT 'users_management',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample data
INSERT INTO project1.users (name, email, role) VALUES 
    ('Alice Johnson', 'alice@company.com', 'admin'),
    ('Bob Smith', 'bob@company.com', 'user'),
    ('Carol Davis', 'carol@company.com', 'manager')
ON CONFLICT (email) DO NOTHING;

-- Enable RLS
ALTER TABLE project1.users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY IF NOT EXISTS \"Users can view all users\" ON project1.users FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS \"Users can insert\" ON project1.users FOR INSERT WITH CHECK (true);
CREATE POLICY IF NOT EXISTS \"Users can update own data\" ON project1.users FOR UPDATE USING (true);

-- Grant permissions
GRANT USAGE ON SCHEMA project1 TO anon, authenticated;
GRANT ALL ON project1.users TO anon, authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA project1 TO anon, authenticated;
"

# Project 2: E-commerce
echo "Creating Project 2: E-commerce..."
docker exec supabase-db psql -U postgres -d postgres -c "
-- Create project2 schema
CREATE SCHEMA IF NOT EXISTS project2;

-- Products table
CREATE TABLE IF NOT EXISTS project2.products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category TEXT,
    stock_quantity INTEGER DEFAULT 0,
    project TEXT DEFAULT 'ecommerce',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Orders table
CREATE TABLE IF NOT EXISTS project2.orders (
    id SERIAL PRIMARY KEY,
    customer_email TEXT NOT NULL,
    product_id INTEGER REFERENCES project2.products(id),
    quantity INTEGER NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    project TEXT DEFAULT 'ecommerce',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample products
INSERT INTO project2.products (name, description, price, category, stock_quantity) VALUES 
    ('MacBook Pro', 'Latest MacBook Pro with M3 chip', 1999.99, 'Electronics', 10),
    ('Wireless Mouse', 'Ergonomic wireless mouse', 49.99, 'Accessories', 50),
    ('USB-C Cable', '2m USB-C charging cable', 19.99, 'Accessories', 100),
    ('Monitor Stand', 'Adjustable aluminum monitor stand', 79.99, 'Accessories', 25)
ON CONFLICT DO NOTHING;

-- Insert sample orders
INSERT INTO project2.orders (customer_email, product_id, quantity, total_amount, status) VALUES 
    ('customer1@example.com', 1, 1, 1999.99, 'completed'),
    ('customer2@example.com', 2, 2, 99.98, 'pending'),
    ('customer3@example.com', 3, 3, 59.97, 'shipped')
ON CONFLICT DO NOTHING;

-- Enable RLS
ALTER TABLE project2.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE project2.orders ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY IF NOT EXISTS \"Products are viewable by everyone\" ON project2.products FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS \"Orders are viewable by everyone\" ON project2.orders FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS \"Anyone can insert orders\" ON project2.orders FOR INSERT WITH CHECK (true);

-- Grant permissions
GRANT USAGE ON SCHEMA project2 TO anon, authenticated;
GRANT ALL ON project2.products TO anon, authenticated;
GRANT ALL ON project2.orders TO anon, authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA project2 TO anon, authenticated;
"

# Project 3: Blog/CMS
echo "Creating Project 3: Blog/CMS..."
docker exec supabase-db psql -U postgres -d postgres -c "
-- Create project3 schema
CREATE SCHEMA IF NOT EXISTS project3;

-- Authors table
CREATE TABLE IF NOT EXISTS project3.authors (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    bio TEXT,
    avatar_url TEXT,
    project TEXT DEFAULT 'blog_cms',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Posts table
CREATE TABLE IF NOT EXISTS project3.posts (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    content TEXT,
    excerpt TEXT,
    author_id INTEGER REFERENCES project3.authors(id),
    status TEXT DEFAULT 'draft',
    published_at TIMESTAMP,
    project TEXT DEFAULT 'blog_cms',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Comments table
CREATE TABLE IF NOT EXISTS project3.comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES project3.posts(id),
    author_name TEXT NOT NULL,
    author_email TEXT NOT NULL,
    content TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    project TEXT DEFAULT 'blog_cms',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample authors
INSERT INTO project3.authors (name, email, bio) VALUES 
    ('John Writer', 'john@blog.com', 'Tech blogger and developer'),
    ('Sarah Editor', 'sarah@blog.com', 'Content editor and journalist'),
    ('Mike Reviewer', 'mike@blog.com', 'Product reviewer and analyst')
ON CONFLICT (email) DO NOTHING;

-- Insert sample posts
INSERT INTO project3.posts (title, slug, content, excerpt, author_id, status, published_at) VALUES 
    ('Getting Started with Supabase', 'getting-started-supabase', 'Complete guide to Supabase...', 'Learn the basics of Supabase', 1, 'published', NOW() - INTERVAL '1 day'),
    ('Building APIs with PostgreSQL', 'building-apis-postgresql', 'How to create REST APIs...', 'API development made easy', 2, 'published', NOW() - INTERVAL '2 days'),
    ('Database Design Best Practices', 'database-design-practices', 'Essential database design tips...', 'Design better databases', 1, 'draft', NULL)
ON CONFLICT (slug) DO NOTHING;

-- Insert sample comments
INSERT INTO project3.comments (post_id, author_name, author_email, content) VALUES 
    (1, 'Reader One', 'reader1@example.com', 'Great article! Very helpful.'),
    (1, 'Developer Two', 'dev2@example.com', 'Thanks for the tutorial.'),
    (2, 'API Fan', 'apifan@example.com', 'Excellent explanation of API design.')
ON CONFLICT DO NOTHING;

-- Enable RLS
ALTER TABLE project3.authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE project3.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE project3.comments ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY IF NOT EXISTS \"Authors are viewable by everyone\" ON project3.authors FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS \"Published posts are viewable\" ON project3.posts FOR SELECT USING (status = 'published' OR true);
CREATE POLICY IF NOT EXISTS \"Comments are viewable\" ON project3.comments FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS \"Anyone can add comments\" ON project3.comments FOR INSERT WITH CHECK (true);

-- Grant permissions
GRANT USAGE ON SCHEMA project3 TO anon, authenticated;
GRANT ALL ON project3.authors TO anon, authenticated;
GRANT ALL ON project3.posts TO anon, authenticated;
GRANT ALL ON project3.comments TO anon, authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA project3 TO anon, authenticated;
"

echo "✅ Multi-Project Setup Complete!"
echo ""
echo "🌐 Available Projects:"
echo ""
echo "  📊 Project 1: Users Management"
echo "    Schema: project1"
echo "    Tables: users"
echo "    API: http://localhost:8000/rest/v1/users"
echo ""
echo "  🛍️  Project 2: E-commerce"
echo "    Schema: project2" 
echo "    Tables: products, orders"
echo "    API: http://localhost:8000/rest/v1/products"
echo "    API: http://localhost:8000/rest/v1/orders"
echo ""
echo "  📝 Project 3: Blog/CMS"
echo "    Schema: project3"
echo "    Tables: authors, posts, comments"
echo "    API: http://localhost:8000/rest/v1/authors"
echo "    API: http://localhost:8000/rest/v1/posts"
echo "    API: http://localhost:8000/rest/v1/comments"
echo ""
echo "💡 Example API calls:"
echo "  # Get users from Project 1"
echo "  curl 'http://localhost:8000/rest/v1/users' -H 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE'"
echo ""
echo "  # Get products from Project 2"
echo "  curl 'http://localhost:8000/rest/v1/products' -H 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE'"
echo ""
echo "  # Get blog posts from Project 3"
echo "  curl 'http://localhost:8000/rest/v1/posts' -H 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE'"
echo ""
echo "🎯 Dashboard: http://localhost:8000 (login: supabase / this_password_is_insecure_and_should_be_updated)"