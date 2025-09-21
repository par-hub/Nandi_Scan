-- Migration script to fix user_defined_features table for UUID support
-- Run this in your Supabase SQL Editor

-- Step 1: Check current schema
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_defined_features' 
AND column_name = 'user_id';

-- Step 2: Check if there's any data in the table
SELECT COUNT(*) as record_count FROM user_defined_features;

-- Step 3: If you have data, backup the table first (optional)
-- CREATE TABLE user_defined_features_backup AS SELECT * FROM user_defined_features;

-- Step 4: Drop the foreign key constraint if it exists
-- First, find the constraint name
SELECT conname, conrelid::regclass, confrelid::regclass
FROM pg_constraint 
WHERE conrelid = 'user_defined_features'::regclass 
AND contype = 'f';

-- Drop the constraint (replace 'constraint_name' with actual name from above query)
-- ALTER TABLE user_defined_features DROP CONSTRAINT IF EXISTS user_defined_features_user_id_fkey;

-- Step 5: Change the column type from INTEGER to TEXT
ALTER TABLE user_defined_features ALTER COLUMN user_id TYPE TEXT;

-- Step 6: Add the foreign key constraint back with TEXT reference
ALTER TABLE user_defined_features 
ADD CONSTRAINT user_defined_features_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES User_details(user_id);

-- Step 7: Verify the changes
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_defined_features' 
AND column_name = 'user_id';

-- Step 8: Update RLS policies for user_defined_features to work with TEXT user_id
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can insert own features" ON user_defined_features;
DROP POLICY IF EXISTS "Users can view own features" ON user_defined_features;
DROP POLICY IF EXISTS "Users can update own features" ON user_defined_features;
DROP POLICY IF EXISTS "Users can delete own features" ON user_defined_features;

-- Create new policies with proper UUID comparison
CREATE POLICY "Users can insert own features" 
ON user_defined_features FOR INSERT 
WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can view own features" 
ON user_defined_features FOR SELECT 
USING (auth.uid()::text = user_id);

CREATE POLICY "Users can update own features" 
ON user_defined_features FOR UPDATE 
USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own features" 
ON user_defined_features FOR DELETE 
USING (auth.uid()::text = user_id);

-- Step 9: Test the table with a sample query (this should work without errors)
SELECT * FROM user_defined_features LIMIT 1;

COMMENT ON TABLE user_defined_features IS 'Updated to use TEXT user_id for UUID support';