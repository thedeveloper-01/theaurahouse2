-- Quick fix: Add display_name column to users table
-- This can be run directly on your Render database

-- Add display_name column if it doesn't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR(100);

