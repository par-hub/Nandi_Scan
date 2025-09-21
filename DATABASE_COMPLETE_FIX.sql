-- COMPLETE DATABASE SCHEMA FIX
-- This will add missing columns and fix data types for Supabase UUID compatibility

-- Step 1: Add missing email column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User_details' AND column_name = 'email') THEN
        ALTER TABLE User_details ADD COLUMN email VARCHAR(255);
        RAISE NOTICE 'Added email column to User_details table';
    END IF;
END $$;

-- Step 2: Change user_id from INTEGER to TEXT for UUID support
DO $$
BEGIN
    -- Check if user_id is currently INTEGER
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'User_details' 
               AND column_name = 'user_id' 
               AND data_type = 'integer') THEN
        
        -- If table has data, you might need to clear it first
        -- TRUNCATE TABLE User_details; -- Uncomment if needed
        
        ALTER TABLE User_details ALTER COLUMN user_id TYPE TEXT;
        RAISE NOTICE 'Changed user_id from INTEGER to TEXT for UUID support';
    END IF;
END $$;

-- Step 3: Ensure all required columns exist
DO $$
BEGIN
    -- Add address column if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User_details' AND column_name = 'address') THEN
        ALTER TABLE User_details ADD COLUMN address VARCHAR(255);
    END IF;
    
    -- Add cattles_owned column if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User_details' AND column_name = 'cattles_owned') THEN
        ALTER TABLE User_details ADD COLUMN cattles_owned INTEGER DEFAULT 0;
    END IF;
    
    -- Add gender column if missing  
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User_details' AND column_name = 'gender') THEN
        ALTER TABLE User_details ADD COLUMN gender VARCHAR(10);
    END IF;
    
    -- Add age column if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User_details' AND column_name = 'age') THEN
        ALTER TABLE User_details ADD COLUMN age INTEGER;
    END IF;
END $$;

-- Step 4: Show final schema
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'User_details'
ORDER BY ordinal_position;

-- Step 5: Test insertion with sample data
-- INSERT INTO User_details (user_id, name, phone_number, email) 
-- VALUES ('test-uuid-123', 'Test User', 1234567890, 'test@example.com');

-- Step 6: Verify test data
-- SELECT * FROM User_details WHERE user_id = 'test-uuid-123';

-- Step 7: Clean up test data  
-- DELETE FROM User_details WHERE user_id = 'test-uuid-123';