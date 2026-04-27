-- Database update script to match requirements
USE recipe_db;

-- 1. Update Users Table
ALTER TABLE Users ADD COLUMN Created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- 2. Update Recipes Table
-- Renaming Difficulty_Level to Difficulty
ALTER TABLE Recipes CHANGE COLUMN Difficulty_Level Difficulty VARCHAR(50);

-- 3. Update Recipe_Ingredients Table
-- Adding Mapping_ID as Primary Key
ALTER TABLE Recipe_Ingredients ADD COLUMN Mapping_ID INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- 4. Create Community_Feed Table
CREATE TABLE IF NOT EXISTS Community_Feed (
    Post_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT,
    Recipe_ID INT,
    Caption TEXT,
    Image_URL VARCHAR(255),
    Created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (User_ID) REFERENCES Users(User_ID) ON DELETE CASCADE,
    FOREIGN KEY (Recipe_ID) REFERENCES Recipes(Recipe_ID) ON DELETE CASCADE
);

-- 5. Create Bookmarks Table
CREATE TABLE IF NOT EXISTS Bookmarks (
    Bookmark_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT,
    Recipe_ID INT,
    Saved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (User_ID) REFERENCES Users(User_ID) ON DELETE CASCADE,
    FOREIGN KEY (Recipe_ID) REFERENCES Recipes(Recipe_ID) ON DELETE CASCADE
);

-- 6. Create Dashboard Table (Analytics)
CREATE TABLE IF NOT EXISTS Dashboard (
    Dashboard_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT,
    Total_Recipes INT DEFAULT 0,
    Total_Bookmarks INT DEFAULT 0,
    Pantry_Items INT DEFAULT 0,
    Last_Active TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (User_ID) REFERENCES Users(User_ID) ON DELETE CASCADE
);
