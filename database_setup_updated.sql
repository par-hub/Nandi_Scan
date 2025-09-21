-- Updated SQL commands to create the required tables in Supabase
-- Run these in your Supabase SQL Editor

-- Drop existing tables if they exist (to recreate with correct types)
DROP TABLE IF EXISTS user_defined_features;
DROP TABLE IF EXISTS Features;
DROP TABLE IF EXISTS common_diseases;
DROP TABLE IF EXISTS cow_buffalo;
DROP TABLE IF EXISTS User_details;

-- 1. Create User_details table
CREATE TABLE User_details (
    user_id INTEGER PRIMARY KEY,
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
-- IMPORTANT: The 'id' in this table corresponds to the breed ID from cow_buffalo table
-- This creates a relationship where diseases are linked to specific breeds
CREATE TABLE common_diseases (
    id SERIAL PRIMARY KEY,  -- This ID matches the breed ID from cow_buffalo table
    diseases VARCHAR(255) NOT NULL  -- Using 'diseases' (plural) as per actual database schema
);

-- 4. Create Features table (for health characteristics)
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
    fertility_age FLOAT,
    weight INTEGER,
    udder INTEGER,
    purpose VARCHAR(255),
    teat INTEGER,
    milk_yield FLOAT,
    distinctive_feature VARCHAR(255)
);

-- 5. Create user_defined_features table with updated data types
CREATE TABLE user_defined_features (
    specified_id SERIAL PRIMARY KEY,
    height FLOAT,                    -- Changed from DECIMAL to FLOAT
    color VARCHAR(255),
    weight DECIMAL(10,2),
    user_id INTEGER NOT NULL REFERENCES User_details(user_id),        -- Changed from TEXT to INTEGER and added foreign key
    breed_id INTEGER REFERENCES cow_buffalo(id),
    gender VARCHAR(10)
);

-- 6. Insert sample data into common_diseases
INSERT INTO common_diseases (disease) VALUES
('Foot and Mouth Disease'),
('Mastitis'),
('Pneumonia'),
('Diarrhea'),
('Bloat'),
('Milk Fever'),
('Ketosis'),
('Lameness'),
('Pink Eye'),
('Respiratory Disease'),
('Parasitic Infection'),
('Vitamin Deficiency'),
('Mineral Deficiency'),
('Heat Stress'),
('Cold Stress');

-- 3. Insert the breed data from your CSV
INSERT INTO cow_buffalo (id, breed, gender, count) VALUES
(1, 'murrah', 'm', 0),
(2, 'murrah', 'f', 0),
(3, 'NILI RAVI', 'm', 0),
(4, 'NILI RAVI', 'f', 0),
(5, 'BHADAWARI', 'm', 0),
(6, 'BHADAWARI', 'f', 0),
(7, 'JAFFARABADI', 'm', 0),
(8, 'JAFFARABADI', 'f', 0),
(9, 'SURTI', 'm', 0),
(10, 'SURTI', 'f', 0),
(11, 'MEHSANA', 'm', 0),
(12, 'MEHSANA', 'f', 0),
(13, 'NAGPURI', 'm', 0),
(14, 'NAGPURI', 'f', 0),
(15, 'GODAVARI', 'm', 0),
(16, 'GODAVARI', 'f', 0),
(17, 'TODA', 'm', 0),
(18, 'TODA', 'f', 0),
(19, 'PANDHARPURI', 'm', 0),
(20, 'PANDHARPURI', 'f', 0),
(21, 'Gaolao', 'm', 0),
(22, 'Gaolao', 'f', 0),
(23, 'Ghumusari', 'm', 0),
(24, 'Ghumusari', 'f', 0),
(25, 'Gir', 'm', 0),
(26, 'Gir', 'f', 0),
(27, 'Hallikar', 'm', 0),
(28, 'Hallikar', 'f', 0),
(29, 'Hariana', 'm', 0),
(30, 'Hariana', 'f', 0),
(31, 'Himachali Pahari', 'm', 0),
(32, 'Himachali Pahari', 'f', 0),
(33, 'Kangayam', 'm', 0),
(34, 'Kangayam', 'f', 0),
(35, 'Amritmahal', 'm', 0),
(36, 'Amritmahal', 'f', 0),
(37, 'Bachaur', 'm', 0),
(38, 'Bachaur', 'f', 0),
(39, 'Bargur', 'm', 0),
(40, 'Bargur', 'f', 0),
(41, 'Dangi', 'm', 0),
(42, 'Dangi', 'f', 0),
(43, 'Deoni', 'm', 0),
(44, 'Deoni', 'f', 0),
(45, 'Dhanni', 'm', 0),
(46, 'Dhanni', 'f', 0),
(47, 'Gangatiri', 'm', 0),
(48, 'Gangatiri', 'f', 0),
(49, 'Kankrej', 'm', 0),
(50, 'Kankrej', 'f', 0);
-- Add more breeds as needed from your CSV file

-- 6. Add sample common_diseases data (using 'diseases' column as per actual schema)
INSERT INTO common_diseases (id, diseases) VALUES
(15, 'Foot and Mouth Disease'),
(16, 'Mastitis'),
(7, 'Milk Fever'),
(8, 'Bloat'),
(11, 'Pneumonia'),
(12, 'Diarrhea'),
(13, 'Lumpy Skin Disease'),
(14, 'Tuberculosis'),
(31, 'Brucellosis'),
(32, 'Anthrax'),
(43, 'Black Quarter'),
(44, 'Hemorrhagic Septicemia'),
(1, 'Rinderpest'),
(2, 'Contagious Bovine Pleuropneumonia'),
(3, 'Johnes Disease'),
(4, 'Bovine Viral Diarrhea'),
(5, 'Infectious Bovine Rhinotracheitis'),
(6, 'Paratuberculosis'),
(25, 'Anaplasmosis'),
(26, 'Babesiosis'),
(49, 'Trypanosomiasis'),
(50, 'Theileriosis');

-- 7. Enable Row Level Security (RLS) for security
ALTER TABLE User_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE cow_buffalo ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_defined_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE common_diseases ENABLE ROW LEVEL SECURITY;
ALTER TABLE Features ENABLE ROW LEVEL SECURITY;

-- 8. Create policies for public read access to cow_buffalo
CREATE POLICY "Allow public read access on cow_buffalo" 
ON cow_buffalo FOR SELECT 
TO anon, authenticated 
USING (true);

-- 9. Create policies for common_diseases (public read access)
CREATE POLICY "Allow public read access on common_diseases" 
ON common_diseases FOR SELECT 
TO anon, authenticated 
USING (true);

-- 10. Create policies for Features (public read access)
CREATE POLICY "Allow public read access on Features" 
ON Features FOR SELECT 
TO anon, authenticated 
USING (true);

-- 11. Create policies for User_details
CREATE POLICY "Users can manage their own details" 
ON User_details FOR ALL
TO anon, authenticated 
USING (true) 
WITH CHECK (true);

-- 12. Create policies for user_defined_features
CREATE POLICY "Users can insert their own data" 
ON user_defined_features FOR INSERT 
TO anon, authenticated 
WITH CHECK (true);

CREATE POLICY "Users can view their own data" 
ON user_defined_features FOR SELECT 
TO anon, authenticated 
USING (true);

-- 13. Allow anonymous users to update cow_buffalo count
CREATE POLICY "Allow count updates on cow_buffalo" 
ON cow_buffalo FOR UPDATE 
TO anon, authenticated 
USING (true) 
WITH CHECK (true);

-- 14. Allow users to update and delete their own data
CREATE POLICY "Users can update their own data" 
ON user_defined_features FOR UPDATE 
TO anon, authenticated 
USING (true) 
WITH CHECK (true);

CREATE POLICY "Users can delete their own data" 
ON user_defined_features FOR DELETE 
TO anon, authenticated 
USING (true);