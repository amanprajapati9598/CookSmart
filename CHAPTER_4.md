# CHAPTER 4: SYSTEM DESIGN

## 4.1 Schema Design – CookSmart
The schema design defines the structure of the database used in the CookSmart application. It includes various tables such as Users, Recipes, Ingredients, and other supporting entities that help in managing the application efficiently.
The database is designed using relational structure to ensure data consistency, integrity, and efficient retrieval.

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
The CookSmart database schema is designed to efficiently manage user data, recipes, ingredients, and user interactions. The use of relational tables ensures proper data normalization and avoids redundancy.
The mapping table (Recipe_Ingredients) plays a crucial role in handling complex relationships between recipes and ingredients. Additionally, tables such as Bookmarks and Community Feed enhance user engagement and personalization within the application.

---

## 4.2 Unified Modeling Language (UML)
UML diagrams are used to visually represent the system structure and behavior. They help in understanding how the system works internally and externally.

### 4.2.1 ER Diagram
The ER Diagram represents the relationship between different entities such as User, Recipe, Ingredient, and Bookmark.
> *[Insert ER Diagram Here]*

### 4.2.2 Data Flow Diagram (DFD)
The DFD shows how data flows through the system.
- **DFD Level 0:** 
> *[Insert DFD Level 0 Image Here]*
- **DFD Level 1:** 
> *[Insert DFD Level 1 Image Here]*

### 4.2.3 Class Diagram
The Class Diagram represents object-oriented structure.
> *[Insert Class Diagram Here]*

### 4.2.4 Use Case Diagram
The Use Case Diagram shows interaction between users and system.
> *[Insert Use Case Diagram Here]*

### 4.2.5 Sequence Diagram
The Sequence Diagram shows step-by-step interaction between system components.
> *[Insert Sequence Diagram Here]*

### 4.2.6 Activity Diagram
The Activity Diagram represents workflow of the system.
> *[Insert Activity Diagram Here]*

### 4.2.7 State Transition Diagram
This diagram shows different states of the system.
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
