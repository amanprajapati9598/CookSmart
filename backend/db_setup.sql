CREATE DATABASE IF NOT EXISTS recipe_db;
USE recipe_db;

CREATE TABLE IF NOT EXISTS Users (
    User_ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    Password VARCHAR(255),
    Allergies TEXT,
    Created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Ingredients (
    Ingredient_ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100),
    Category VARCHAR(100),
    Expiry_Duration INT,
    Substitutes VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS Recipes (
    Recipe_ID INT AUTO_INCREMENT PRIMARY KEY,
    Title VARCHAR(255),
    Instructions TEXT,
    Cooking_Time INT,
    Calories INT,
    Difficulty VARCHAR(50),
    Is_Veg BOOLEAN,
    Image_URL VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS Recipe_Ingredients (
    Mapping_ID INT AUTO_INCREMENT PRIMARY KEY,
    Recipe_ID INT,
    Ingredient_ID INT,
    Quantity VARCHAR(100),
    FOREIGN KEY (Recipe_ID) REFERENCES Recipes(Recipe_ID) ON DELETE CASCADE,
    FOREIGN KEY (Ingredient_ID) REFERENCES Ingredients(Ingredient_ID) ON DELETE CASCADE
);

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

CREATE TABLE IF NOT EXISTS Bookmarks (
    Bookmark_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT,
    Recipe_ID INT,
    Saved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (User_ID) REFERENCES Users(User_ID) ON DELETE CASCADE,
    FOREIGN KEY (Recipe_ID) REFERENCES Recipes(Recipe_ID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Dashboard (
    Dashboard_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT,
    Total_Recipes INT DEFAULT 0,
    Total_Bookmarks INT DEFAULT 0,
    Pantry_Items INT DEFAULT 0,
    Last_Active TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (User_ID) REFERENCES Users(User_ID) ON DELETE CASCADE
);

-- Insert sample ingredients
INSERT IGNORE INTO Ingredients (Ingredient_ID, Name, Category, Expiry_Duration, Substitutes) VALUES 
(1, 'Paneer', 'Dairy', 5, 'Tofu'),
(2, 'Palak', 'Vegetable', 3, 'Mustard Greens'),
(3, 'Tamatar', 'Vegetable', 7, 'Tomato Puree'),
(4, 'Pyaj', 'Vegetable', 30, 'Leek'),
(5, 'Butter', 'Dairy', 60, 'Oil, Ghee'),
(6, 'Salt', 'Spice', 365, NULL),
(7, 'Oil', 'Pantry', 365, 'Butter, Ghee'),
(8, 'Ghee', 'Dairy', 365, 'Oil, Butter');

-- Insert sample recipes
INSERT IGNORE INTO Recipes (Recipe_ID, Title, Instructions, Cooking_Time, Calories, Difficulty, Is_Veg, Image_URL) VALUES 
(101, 'Palak Paneer', '1. Blanch palak and puree it.\n2. Heat a pan, add butter, onions, and tomatoes.\n3. Cook until soft, then add palak puree and spices.\n4. Lastly add paneer cubes and let it simmer.\n5. Serve hot with roti.', 30, 350, 'Medium', 1, 'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&q=80&w=800'),
(102, 'Paneer Tikka', '1. Cut paneer and veggies into cubes.\n2. Marinate with yogurt and spices minimum for 1 hour.\n3. Grill until charred and golden.\n4. Serve hot with mint chutney.', 20, 250, 'Beginner', 1, 'https://images.unsplash.com/photo-1628296509355-ceeeff10e0ff?auto=format&fit=crop&q=80&w=800'),
(103, 'Tomato Soup', '1. Boil tomatoes with an onion and garlic.\n2. Blend and strain the soup.\n3. Heat pan with butter, pour tomato juice, simmer, and add salt.\n4. Serve hot with bread.', 15, 120, 'Beginner', 1, 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&q=80&w=800');

-- Insert recipe ingredients
INSERT IGNORE INTO Recipe_Ingredients (Recipe_ID, Ingredient_ID, Quantity) VALUES 
(101, 1, '200g'),
(101, 2, '500g'),
(101, 3, '2 units'),
(101, 4, '1 unit'),
(101, 5, '2 tbsp'),
(101, 6, 'to taste'),
(102, 1, '250g'),
(102, 4, '1 unit'),
(102, 3, '1 unit'),
(102, 7, '1 tbsp'),
(102, 6, 'to taste'),
(103, 3, '4 units'),
(103, 4, '1 unit'),
(103, 5, '1 tbsp'),
(103, 6, 'to taste');
