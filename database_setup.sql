-- SQL commands to create the required tables in Supabase
-- Run these in your Supabase SQL Editor

-- 1. Create cow_buffalo table
CREATE TABLE IF NOT EXISTS cow_buffalo (
    id SERIAL PRIMARY KEY,
    breed VARCHAR(255) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    count INTEGER DEFAULT 0
);

-- 2. Create user_defined_features table
CREATE TABLE IF NOT EXISTS user_defined_features (
    specified_id SERIAL PRIMARY KEY,
    height FLOAT,
    color VARCHAR(255),
    weight DECIMAL(10,2),
    user_id INTEGER NOT NULL,
    breed_id INTEGER REFERENCES cow_buffalo(id),
    gender VARCHAR(10)
);

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

-- 4. Enable Row Level Security (RLS) for security
ALTER TABLE cow_buffalo ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_defined_features ENABLE ROW LEVEL SECURITY;

-- 5. Create policies for public read access to cow_buffalo
CREATE POLICY "Allow public read access on cow_buffalo" 
ON cow_buffalo FOR SELECT 
TO anon, authenticated 
USING (true);

-- 6. Create policies for user_defined_features
CREATE POLICY "Users can insert their own data" 
ON user_defined_features FOR INSERT 
TO anon, authenticated 
WITH CHECK (true);

CREATE POLICY "Users can view their own data" 
ON user_defined_features FOR SELECT 
TO anon, authenticated 
USING (true);

-- 7. Allow anonymous users to update cow_buffalo count
CREATE POLICY "Allow count updates on cow_buffalo" 
ON cow_buffalo FOR UPDATE 
TO anon, authenticated 
USING (true) 
WITH CHECK (true);