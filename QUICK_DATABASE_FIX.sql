-- QUICK DATABASE SCHEMA FIX
-- Run this in your Supabase SQL Editor to fix the user_id column

-- Step 1: Check current schema (this will show you the current column type)
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'User_details';

-- Step 2: If user_id is INTEGER, convert it to TEXT
-- WARNING: This will only work if the table is empty or has compatible data
ALTER TABLE User_details ALTER COLUMN user_id TYPE TEXT;

-- Step 3: Verify the change
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'User_details' 
AND column_name = 'user_id';

-- Step 4: Test insertion with a sample UUID
-- INSERT INTO User_details (user_id, name, phone_number, email) 
-- VALUES ('test-uuid-123', 'Test User', 1234567890, 'test@example.com');

-- Step 5: Clean up test data
-- DELETE FROM User_details WHERE user_id = 'test-uuid-123';