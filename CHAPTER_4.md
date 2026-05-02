# CHAPTER 4: SYSTEM DESIGN

## 4.1 Schema Design – CookSmart
The schema design serves as the foundational architecture for the CookSmart application, dictating exactly how data is organized, stored, retrieved, and managed across the entire system. Because CookSmart is a data-intensive platform—handling everything from user authentication to complex AI-driven recipe generation and social community feeds—the underlying database structure must be exceptionally robust, highly optimized, and meticulously organized.

#### 1. The Choice of a Relational Database Management System (RDBMS)
For the CookSmart application, a Relational Database Management System (specifically MySQL) was selected as the backend data storage solution. This choice was driven by the highly structured nature of culinary data. Recipes, ingredients, and user profiles possess clear, definable relationships. Unlike NoSQL databases (which are better suited for unstructured, document-based data), a relational structure enforces strict data typing and allows for complex `JOIN` operations. This is absolutely critical for CookSmart's primary feature: the "Smart Pantry." Calculating exactly which recipes a user can cook based on their current inventory requires mathematically comparing sets of ingredients against recipes—a task at which relational databases utilizing structured query language (SQL) excel.

#### 2. Core Architectural Objectives
The schema was designed from the ground up with three primary objectives in mind:
- **Data Integrity and Consistency:** Ensuring that the data remains accurate over time. By utilizing strict Primary Keys (PK) and Foreign Keys (FK), the schema prevents orphaned records. For example, a user cannot save a bookmark for a recipe that has been deleted from the database.
- **Query Optimization and Mobile Performance:** The Flutter mobile frontend requires extremely low-latency responses from the PHP backend API to ensure a smooth user experience (UX). To achieve this, the schema is heavily indexed. Numerical integer IDs are used for all primary relationships rather than string-based keys, drastically reducing the time it takes for the database engine to execute searches and joins.
- **Modular Scalability:** The database is not monolithic. It is modularly separated into discrete entities (Users, Recipes, Community Feeds). This means that if the application scales in the future—for instance, if the development team decides to add a "Video Tutorials" feature or a "Premium Subscription" tier—new tables can be integrated without breaking the existing schema architecture.

#### 3. Database Normalization Strategy
To eliminate data redundancy and prevent data anomalies (issues that arise when updating, inserting, or deleting data), the CookSmart schema adheres to the principles of database normalization, specifically targeting the Third Normal Form (3NF). 
In a poorly designed, unnormalized database, a single "Recipe" row might contain columns for `Ingredient_1`, `Ingredient_2`, `Ingredient_3`, etc. This creates massive inefficiencies and limits the number of ingredients a recipe can have. Instead, the CookSmart schema separates this data into distinct `Recipes` and `Ingredients` tables. It then bridges them together using a specialized mapping table. This normalized approach ensures that an ingredient's specific details (like its category or shelf life) are stored only once in the entire system, regardless of how many thousands of recipes utilize it.

#### 4. Mapping the Schema to Application Features
Every table in the schema directly correlates to a core feature of the Flutter application:
- **Authentication & Security:** Handled by the `Users` table, which securely stores hashed passwords and personalized dietary restrictions (allergies).
- **The Core Engine:** Handled by the `Recipes`, `Ingredients`, and the critical `Recipe_Ingredients` mapping tables, which together power the browsing, searching, and AI-pantry logic.
- **User Engagement:** Handled by the `Bookmarks`, `Dashboard`, and `Community Feed` tables, which allow users to save their favorite dishes, track their activity, and share their culinary creations with other users on the platform.

The detailed structure of these individual entities, including their column definitions, data types, and specific roles within the system, is thoroughly documented in the following subsections.

### 4.1.1 Users Table

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **User_ID (PK)** | INT | Unique user identifier |
| **Name** | VARCHAR | User’s full name |
| **Email** | VARCHAR | User’s email address (Unique) |
| **Password** | VARCHAR | Hashed user password |
| **Allergies** | TEXT | User's dietary restrictions or allergies |
| **Created_at** | TIMESTAMP | Account creation date |

### 4.1.2 Recipes Table

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **Recipe_ID (PK)** | INT | Unique recipe identifier |
| **Title** | VARCHAR | Name of the dish |
| **Instructions** | TEXT | Step-by-step cooking guide |
| **Cooking_Time** | INT | Time required (minutes) |
| **Calories** | INT | Nutritional value (kcal) |
| **Difficulty** | VARCHAR | Level (Beginner/Medium/Advanced) |
| **Is_Veg** | BOOLEAN | Vegetarian indicator |
| **Image_URL** | VARCHAR | Recipe image link |

### 4.1.3 Ingredients Table

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **Ingredient_ID (PK)** | INT | Unique ingredient ID |
| **Name** | VARCHAR | Ingredient name |
| **Category** | VARCHAR | Type (Dairy, Veg, Spice, etc.) |
| **Expiry_Duration**| INT | Shelf life (days) |
| **Substitutes** | VARCHAR | Alternative ingredients |

### 4.1.4 Recipe_Ingredients Table (Mapping Table)
This table is used to resolve the many-to-many relationship between Recipes and Ingredients.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **Mapping_ID (PK)**| INT | Unique mapping ID |
| **Recipe_ID (FK)** | INT | Linked recipe |
| **Ingredient_ID (FK)**| INT | Linked ingredient |
| **Quantity** | VARCHAR | Required quantity |

### 4.1.5 Community Feed Table

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **Post_ID (PK)** | INT | Unique post ID |
| **User_ID (FK)** | INT | User who posted |
| **Recipe_ID (FK)** | INT | Related recipe |
| **Caption** | TEXT | Description or experience |
| **Image_URL** | VARCHAR | Uploaded image |
| **Created_at** | TIMESTAMP | Post time |

### 4.1.6 Bookmarks Table

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **Bookmark_ID (PK)**| INT | Unique bookmark ID |
| **User_ID (FK)** | INT | User who saved recipe |
| **Recipe_ID (FK)** | INT | Saved recipe |
| **Saved_at** | TIMESTAMP | Save date |

### 4.1.7 Dashboard Table (Analytics)

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **Dashboard_ID (PK)**| INT | Unique dashboard ID |
| **User_ID (FK)** | INT | Linked user |
| **Total_Recipes** | INT | Total recipes count |
| **Total_Bookmarks**| INT | Saved recipes count |
| **Pantry_Items** | INT | Pantry item count |
| **Last_Active** | TIMESTAMP | Last activity |

### 4.1.8 Summary of Schema Design

The database schema of the CookSmart application has been meticulously engineered to provide a robust, scalable, and highly optimized foundation for handling complex user interactions and advanced AI-driven data processing. At its core, the schema utilizes a strict relational structure managed via MySQL, designed to prioritize data integrity, rapid query execution, and seamless integration with the Flutter frontend through RESTful PHP APIs.

#### 1. Normalization and Data Integrity
A critical focus during the schema design phase was adhering to database normalization principles (primarily achieving the Third Normal Form - 3NF). By systematically decomposing the data into distinct, logical entities (such as `Users`, `Recipes`, and `Ingredients`), the architecture actively prevents data redundancy and insertion/deletion anomalies. For instance, rather than storing a recipe's ingredients as a comma-separated string within the `Recipes` table (which would violate 1NF and make searching impossible), ingredients are stored as distinct records in the `Ingredients` table. This structured separation ensures that if an ingredient's category or expiry duration needs to be updated, it is done in a single central location rather than across thousands of individual recipes.

#### 2. Referential Integrity and Key Constraints
The schema strictly enforces referential integrity through a comprehensive network of Primary Keys (PK) and Foreign Keys (FK). Every entity is assigned a unique, auto-incrementing integer Primary Key (e.g., `User_ID`, `Recipe_ID`). These integer-based keys are highly optimized for indexing, ensuring that complex SQL `JOIN` operations execute with minimal latency. Foreign Keys dictate the hierarchical relationships within the application. For example, the `User_ID` acts as a foreign key in the `Bookmarks` and `Community Feed` tables. This structural dependency ensures that data remains consistent; if a user account is deleted, the database can safely cascade the deletion to remove their associated bookmarks and posts, preventing orphaned data from cluttering the system.

#### 3. Resolving Complex Relationships: The Mapping Table
The most sophisticated aspect of the CookSmart schema is the resolution of the many-to-many (M:N) relationship between `Recipes` and `Ingredients`. A single recipe requires multiple ingredients, and conversely, a common ingredient (like salt or chicken) is utilized in thousands of recipes. To model this, the `Recipe_Ingredients` mapping (or junction) table was introduced. 
This table is not merely a structural necessity; it is the algorithmic heart of the "Smart Pantry" feature. When the user inputs their available ingredients, the backend PHP API performs an aggregated `COUNT` operation combined with an `IN` clause across this mapping table. This allows the system to instantly calculate both the `Total_Ingredients` required for a recipe and the `Matched_Ingredients` based on the user's input. Without this precise mapping table, the core algorithmic functionality of matching pantry items to viable recipes would be mathematically impossible to execute in real-time.

#### 4. Strategic Data Type Selection and Storage Efficiency
Every column within the schema was assigned a specific data type to maximize storage efficiency and application performance. 
- **VARCHAR vs. TEXT:** Short, predictable strings like `Title`, `Name`, or `Email` utilize `VARCHAR` with predefined length limits to conserve memory. Conversely, unpredictable, lengthy data such as recipe `Instructions` or community post `Captions` utilize the `TEXT` data type to accommodate detailed paragraphs without truncation.
- **Booleans and Timestamps:** Binary flags, such as `Is_Veg`, utilize `BOOLEAN` types to allow for hyper-fast filtering in search queries. `TIMESTAMP` fields are heavily utilized across tables (`Created_at`, `Saved_at`, `Last_Active`) to facilitate chronological sorting, enable data analytics, and manage session expirations.

#### 5. Security and Analytical Scalability
The schema design inherently supports the application's security posture. The `Users` table incorporates a dedicated `Password` field explicitly designated for hashed cryptographic strings, ensuring that plain-text passwords are never stored in the database. 
Furthermore, the inclusion of the `Dashboard` table represents a forward-thinking approach to scalability. Rather than forcing the server to dynamically count a user's total bookmarks or pantry items every time they load the home screen, these aggregate metrics are cached in the Dashboard table. This architectural decision significantly reduces the computational load on the database server during high-traffic periods, ensuring the application remains responsive as the user base grows. 

In conclusion, the CookSmart database schema is not merely a passive storage container; it is an active, highly optimized structural framework that directly powers the application’s most advanced features—from AI-assisted matching logic to secure, real-time social networking integrations.

---

## 4.2 Unified Modeling Language (UML) & System Modeling
System modeling is a crucial phase in the software development lifecycle that provides a comprehensive blueprint of the application before actual coding begins. Unified Modeling Language (UML) and Data Flow Diagrams (DFD) are utilized to visually map out both the structural and behavioral aspects of the CookSmart application. This ensures that developers, stakeholders, and designers share a unified understanding of the system's architecture, data handling, and user interactions.

### 4.2.1 Entity-Relationship (ER) Diagram
The Entity-Relationship (ER) Diagram serves as the foundational architecture for the CookSmart database. It visually depicts the logical structure of databases by illustrating how different entities (tables) relate to one another.
- **Core Entities:** The primary entities in CookSmart include `User`, `Recipe`, `Ingredient`, `CommunityFeed`, and `Bookmark`.
- **Relationships:** The ER diagram highlights critical relationships such as a User can have multiple Bookmarks (1:N), a User can create multiple Community Posts (1:N), and the most complex relationship: a Recipe requires multiple Ingredients, and an Ingredient can belong to multiple Recipes (M:N). This many-to-many relationship is resolved using the `Recipe_Ingredients` mapping entity.
- **Attributes:** It also details primary keys (e.g., `User_ID`, `Recipe_ID`) and foreign keys used to link tables, ensuring referential integrity across the MySQL backend.

> *[Insert ER Diagram Here]*

### 4.2.2 Data Flow Diagram (DFD)
The Data Flow Diagram (DFD) is a graphical representation of how data moves through the CookSmart system. It focuses on the flow of information, where data comes from, where it goes, and how it gets stored.

- **DFD Level 0 (Context Diagram):** This is the highest level of abstraction. It treats the entire CookSmart application as a single main process interacting with external entities. It shows the `User` as the primary external entity providing inputs (e.g., Search Queries, Login Credentials, Ingredient inputs) to the central "CookSmart System", and receiving outputs (e.g., Recipe Recommendations, Authentication Status).
> *[Insert DFD Level 0 Image Here]*

- **DFD Level 1:** This diagram provides a more granular view by breaking down the single context process into major sub-processes. For CookSmart, these sub-processes include `1.0 Authentication`, `2.0 Recipe Search & View`, `3.0 Community Feed`, `4.0 Pantry Tracking`, and `5.0 Dashboard Management`. It explicitly details how data flows between the User, these specific processes, and internal data stores like `D2 User DB`, `D3 Recipe DB`, and `D5 Ingredient DB`.
> *[Insert DFD Level 1 Image Here]*

### 4.2.3 Class Diagram
The Class Diagram is a structural UML diagram that maps out the object-oriented design of the Flutter frontend and PHP backend models.
- **Classes & Attributes:** It defines classes like `UserModel`, `RecipeModel`, `IngredientModel`, and `ApiService`. For example, `RecipeModel` contains attributes like `title`, `cookingTime`, and `calories`.
- **Methods:** It outlines the behaviors or operations each class can perform, such as `login()`, `fetchAIRecommendations()`, or `saveBookmark()`.
- **Associations:** The diagram illustrates associations, inheritances, and dependencies, such as the `HomeScreen` UI class depending on the `RecipeProvider` class for state management.

> *[Insert Class Diagram Here]*

### 4.2.4 Use Case Diagram
The Use Case Diagram defines the behavioral requirements of CookSmart from the perspective of the end-user. It identifies the actors (users) and their interactions with the system's core functionalities.
- **Actors:** The primary actor is the `Registered User`, and a secondary actor might be the `Guest User` or the `Admin`.
- **Use Cases:** Key use cases include "Sign Up / Log In", "Search Recipes by Ingredients", "Get AI Recommendations", "Manage Pantry Inventory", "Save/Bookmark Recipe", and "Post to Community Feed".
- **Relationships:** It shows `<<include>>` relationships (e.g., "Post to Community Feed" includes "Authenticate User") and `<<extend>>` relationships (e.g., "Reset Password" extends "Log In" if the user forgets their password).

> *[Insert Use Case Diagram Here]*

### 4.2.5 Sequence Diagram
The Sequence Diagram is a dynamic modeling tool that details the chronological sequence of messages and interactions between system components to execute a specific task.
- **Example Flow - AI Recipe Generation:** It maps the vertical lifelines of the `User`, `Flutter UI`, `API Service Layer`, `PHP Backend`, and the external `Gemini AI API`. It shows the step-by-step horizontal messaging: the User clicks "Search", the UI triggers an async function in the API service, the service formats the prompt and calls the OpenRouter API, the AI returns a JSON response, the service parses it, and finally, the UI updates state to display the recipes.

> *[Insert Sequence Diagram Here]*

### 4.2.6 Activity Diagram
The Activity Diagram illustrates the step-by-step operational workflows and decision-making logic within the application, functioning much like a sophisticated flowchart.
- **Control Flow:** For CookSmart, a key activity diagram maps the "Smart Search Workflow". It starts with the user entering ingredients. The system checks a decision node: "Are ingredients valid?". If yes, it proceeds to query the database. If local matches are found, it displays them. If no local matches are found, it triggers the secondary workflow to fetch AI recommendations, before reaching the final state of displaying results to the user.

> *[Insert Activity Diagram Here]*

### 4.2.7 State Transition Diagram
The State Transition Diagram focuses on how specific objects transition between different states in response to internal or external events.
- **Application State:** It maps the overall state of the app: from `Splash Screen` -> `Unauthenticated (Login State)` -> `Authenticated (Dashboard State)`.
- **Component State:** It is particularly useful for tracking the state of an asynchronous API call in the Flutter UI. For instance, a Recipe Feed object transitions from `Initial` to `Loading` (showing a spinner) when a fetch is requested, and then transitions to either `Loaded` (displaying data) or `Error` (showing an error snackbar) based on the HTTP response.

> *[Insert State Transition Diagram Here]*

---

## 4.3 User Interface Design
The User Interface Design defines how the application looks and how users interact with it.

**Main Screens:**

1. **Login page:**
> *[Insert Login Page Screenshot Here]*

2. **Home page:**
> *[Insert Home Page Screenshot Here]*

3. **Recipe page:**
> *[Insert Recipe Page Screenshot Here]*

4. **Community cooks page:**
> *[Insert Community Cooks Page Screenshot Here]*

5. **Chatbot page:**
> *[Insert Chatbot Page Screenshot Here]*

6. **Grocery List page:**
> *[Insert Grocery List Page Screenshot Here]*

7. **My profile page:**
> *[Insert My Profile Page Screenshot Here]*

8. **Setting page:**
> *[Insert Setting Page Screenshot Here]*
