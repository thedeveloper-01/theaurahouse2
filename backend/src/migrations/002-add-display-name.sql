-- Migration: Add display_name column to users table
-- This migration adds the display_name column if it doesn't exist
-- Run this with: psql $DATABASE_URL -f src/migrations/002-add-display-name.sql

-- Add display_name column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'display_name'
    ) THEN
        ALTER TABLE users ADD COLUMN display_name VARCHAR(100);
    END IF;
END $$;

