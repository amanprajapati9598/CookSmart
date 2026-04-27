CREATE DATABASE recipe_db;
USE recipe_db;
CREATE TABLE users(
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50),
  email VARCHAR(100),
  password VARCHAR(255)
);
CREATE TABLE recipes(
  recipe_id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(150),
  instructions TEXT,
  cooking_time INT
);