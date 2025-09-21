-- FIXED DATABASE SCHEMA FOR SUPABASE AUTH COMPATIBILITY
-- This version fixes the user_id column to be TEXT to support Supabase UUID strings

-- Drop existing tables first (use this carefully in production)
DROP TABLE IF EXISTS cattle CASCADE;
DROP TABLE IF EXISTS Features CASCADE;
DROP TABLE IF EXISTS common_diseases CASCADE;
DROP TABLE IF EXISTS cow_buffalo CASCADE;
DROP TABLE IF EXISTS User_details CASCADE;

-- 1. Create User_details table with TEXT user_id for Supabase UUID compatibility
CREATE TABLE User_details (
    user_id TEXT PRIMARY KEY,  -- Changed from INTEGER to TEXT for Supabase UUID support
    name VARCHAR(255),
    phone_number BIGINT,
    email VARCHAR(255),
    address VARCHAR(255),
    cattles_owned INTEGER DEFAULT 0,
    gender VARCHAR(10),
    age INTEGER
);

-- 2. Create cow_buffalo table
CREATE TABLE cow_buffalo (
    id SERIAL PRIMARY KEY,
    breed VARCHAR(255) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    count INTEGER DEFAULT 0
);

-- 3. Create common_diseases table
CREATE TABLE common_diseases (
    id SERIAL PRIMARY KEY,
    diseases VARCHAR(255) NOT NULL
);

-- 4. Create Features table
CREATE TABLE Features (
    specification_id SERIAL PRIMARY KEY,
    height FLOAT,
    muscle_type VARCHAR(255),
    hump BOOLEAN,
    color VARCHAR(255),
    pattern VARCHAR(255),
    horn_shape VARCHAR(255),
    ear_shape VARCHAR(255),
    forehead_shape VARCHAR(255),
    gestation_period FLOAT,
    age INTEGER,
    milk_per_day FLOAT,
    user_id TEXT NOT NULL REFERENCES User_details(user_id),  -- Changed to TEXT
    cattles_tag VARCHAR(255) NOT NULL,
    specified_id VARCHAR(255) NOT NULL,
    cattle_name VARCHAR(255),
    date_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Create cattle table
CREATE TABLE cattle (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES User_details(user_id),  -- Changed to TEXT
    specified_id VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    breed VARCHAR(255),
    gender VARCHAR(10),
    age INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS
ALTER TABLE User_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE cow_buffalo ENABLE ROW LEVEL SECURITY;
ALTER TABLE common_diseases ENABLE ROW LEVEL SECURITY;
ALTER TABLE Features ENABLE ROW LEVEL SECURITY;
ALTER TABLE cattle ENABLE ROW LEVEL SECURITY;

-- Create policies for User_details
CREATE POLICY "Users can view own data" 
ON User_details FOR ALL
USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own data" 
ON User_details FOR INSERT
WITH CHECK (auth.uid()::text = user_id);

-- Create policies for Features
CREATE POLICY "Users can view own features" 
ON Features FOR ALL
USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own features" 
ON Features FOR INSERT
WITH CHECK (auth.uid()::text = user_id);

-- Create policies for cattle
CREATE POLICY "Users can view own cattle" 
ON cattle FOR ALL
USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own cattle" 
ON cattle FOR INSERT
WITH CHECK (auth.uid()::text = user_id);

-- Public access for reference tables
CREATE POLICY "Allow read access to cow_buffalo" 
ON cow_buffalo FOR SELECT
USING (true);

CREATE POLICY "Allow read access to common_diseases" 
ON common_diseases FOR SELECT
USING (true);

-- Insert sample breeds (you can modify these as needed)
INSERT INTO cow_buffalo (breed, gender, count) VALUES
('Jersey', 'Female', 0),
('Holstein', 'Female', 0),
('Gir', 'Female', 0),
('Sahiwal', 'Female', 0),
('Red Sindhi', 'Female', 0),
('Jersey', 'Male', 0),
('Holstein', 'Male', 0),
('Gir', 'Male', 0),
('Sahiwal', 'Male', 0),
('Red Sindhi', 'Male', 0);

-- Insert sample diseases (you can modify these as needed)
INSERT INTO common_diseases (diseases) VALUES
('Mastitis'),
('Foot and Mouth Disease'),
('Tuberculosis'),
('Brucellosis'),
('Pneumonia'),
('Diarrhea'),
('Bloat'),
('Milk Fever'),
('Ketosis'),
('Retained Placenta');

-- Test data insertion (remove this in production)
-- INSERT INTO User_details (user_id, name, phone_number, email) VALUES
-- ('sample-uuid-test', 'Test User', 1234567890, 'test@example.com');