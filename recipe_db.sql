-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 25, 2026 at 09:02 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.1.25

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `recipe_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `ingredients`
--

CREATE TABLE `ingredients` (
  `Ingredient_ID` int(11) NOT NULL,
  `Name` varchar(100) DEFAULT NULL,
  `Category` varchar(100) DEFAULT NULL,
  `Expiry_Duration` int(11) DEFAULT NULL,
  `Substitutes` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `ingredients`
--

INSERT INTO `ingredients` (`Ingredient_ID`, `Name`, `Category`, `Expiry_Duration`, `Substitutes`) VALUES
(1, 'Paneer', 'Dairy', 5, 'Tofu'),
(2, 'Palak', 'Vegetable', 3, 'Mustard Greens'),
(3, 'Tamatar', 'Vegetable', 7, 'Tomato Puree'),
(4, 'Pyaj', 'Vegetable', 30, 'Leek'),
(5, 'Butter', 'Dairy', 60, 'Oil, Ghee'),
(6, 'Salt', 'Spice', 365, NULL),
(7, 'Oil', 'Pantry', 365, 'Butter, Ghee'),
(8, 'Ghee', 'Dairy', 365, 'Oil, Butter');

-- --------------------------------------------------------

--
-- Table structure for table `recipes`
--

CREATE TABLE `recipes` (
  `Recipe_ID` int(11) NOT NULL,
  `Title` varchar(255) DEFAULT NULL,
  `Instructions` text DEFAULT NULL,
  `Cooking_Time` int(11) DEFAULT NULL,
  `Calories` int(11) DEFAULT NULL,
  `Difficulty_Level` varchar(50) DEFAULT NULL,
  `Is_Veg` tinyint(1) DEFAULT NULL,
  `Image_URL` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `recipes`
--

INSERT INTO `recipes` (`Recipe_ID`, `Title`, `Instructions`, `Cooking_Time`, `Calories`, `Difficulty_Level`, `Is_Veg`, `Image_URL`) VALUES
(101, 'Palak Paneer', '1. Blanch palak and puree it.\n2. Heat a pan, add butter, onions, and tomatoes.\n3. Cook until soft, then add palak puree and spices.\n4. Lastly add paneer cubes and let it simmer.\n5. Serve hot with roti.', 30, 350, 'Medium', 1, 'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&q=80&w=800'),
(102, 'Paneer Tikka', '1. Cut paneer and veggies into cubes.\n2. Marinate with yogurt and spices minimum for 1 hour.\n3. Grill until charred and golden.\n4. Serve hot with mint chutney.', 20, 250, 'Beginner', 1, 'https://images.unsplash.com/photo-1628296509355-ceeeff10e0ff?auto=format&fit=crop&q=80&w=800'),
(103, 'Tomato Soup', '1. Boil tomatoes with an onion and garlic.\n2. Blend and strain the soup.\n3. Heat pan with butter, pour tomato juice, simmer, and add salt.\n4. Serve hot with bread.', 15, 120, 'Beginner', 1, 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&q=80&w=800');

-- --------------------------------------------------------

--
-- Table structure for table `recipe_ingredients`
--

CREATE TABLE `recipe_ingredients` (
  `Recipe_ID` int(11) DEFAULT NULL,
  `Ingredient_ID` int(11) DEFAULT NULL,
  `Quantity` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `recipe_ingredients`
--

INSERT INTO `recipe_ingredients` (`Recipe_ID`, `Ingredient_ID`, `Quantity`) VALUES
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

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `User_ID` int(11) NOT NULL,
  `Name` varchar(100) DEFAULT NULL,
  `Email` varchar(100) DEFAULT NULL,
  `Password` varchar(255) DEFAULT NULL,
  `Allergies` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`User_ID`, `Name`, `Email`, `Password`, `Allergies`) VALUES
(1, 'Fuzzu', 'fuzzu@gmail.com', '$2y$10$roM4yZ.Nwh53RUIqrfVXyej1xaE5xn53HSGHQv5IB5KaKoPcAag9a', NULL),
(2, 'moti', 'moti@gmail.com', '$2y$10$XjEKp8dnzUIFecL8CJEYOeTKYT.pr.GK1t9OHAowSFw4lb1ah65de', NULL),
(3, 'saumya', 'saumya666@gmail.com', '$2y$10$/qVpRSv/5QOHMz1sKgJrSeu0DNFxl6R6rJcMzhO1FAMMYsHdJv4y6', NULL),
(8, 'Fuzzu', 'fuzzu1@gmail.com', '$2y$10$KUzrh4inMUKVZDtrZovlGOz5f.UlW3kRmw3s7ESrts1k5bGJ9lKvS', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ingredients`
--
ALTER TABLE `ingredients`
  ADD PRIMARY KEY (`Ingredient_ID`);

--
-- Indexes for table `recipes`
--
ALTER TABLE `recipes`
  ADD PRIMARY KEY (`Recipe_ID`);

--
-- Indexes for table `recipe_ingredients`
--
ALTER TABLE `recipe_ingredients`
  ADD KEY `Recipe_ID` (`Recipe_ID`),
  ADD KEY `Ingredient_ID` (`Ingredient_ID`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`User_ID`),
  ADD UNIQUE KEY `Email` (`Email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `ingredients`
--
ALTER TABLE `ingredients`
  MODIFY `Ingredient_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `recipes`
--
ALTER TABLE `recipes`
  MODIFY `Recipe_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=104;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `User_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `recipe_ingredients`
--
ALTER TABLE `recipe_ingredients`
  ADD CONSTRAINT `recipe_ingredients_ibfk_1` FOREIGN KEY (`Recipe_ID`) REFERENCES `recipes` (`Recipe_ID`) ON DELETE CASCADE,
  ADD CONSTRAINT `recipe_ingredients_ibfk_2` FOREIGN KEY (`Ingredient_ID`) REFERENCES `ingredients` (`Ingredient_ID`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
