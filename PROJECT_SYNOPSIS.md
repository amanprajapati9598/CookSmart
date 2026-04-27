# PROJECT SYNOPSIS
## Food Recipe Recommendation Application (CookSmart)

---

### 1. Title of the Project
Food Recipe Recommendation Application (CookSmart)

---

### 2. Introduction
CookSmart is an advanced Health & Lifestyle platform that integrates Artificial Intelligence (AI) with smart kitchen management.
While traditional recipe applications provide only static lists, CookSmart works as a personalized culinary assistant. It intelligently solves the everyday problem of "what to cook" by analyzing ingredients available in the user’s pantry.
By combining nutritional monitoring with inventory management, the system delivers a complete and efficient solution for maintaining a healthy lifestyle.

---

### 3. Problem Statement
Modern households face multiple inefficiencies, which CookSmart aims to solve:
- **Inefficient Inventory Management:** Users lose track of ingredients, leading to waste or duplicate purchases.
- **Nutritional Ignorance:** Lack of real-time calorie and macro tracking.
- **Static Recipe Discovery:** Recipes are not based on available ingredients.
- **Meal Planning Complexity:** Difficult to manage grocery lists with meal plans.

---

### 4. Objectives of the Project
- **To Automate Pantry Tracking:** Maintain real-time ingredient records.
- **To Provide Intelligent Recommendations:** Use Google Gemini (LLM) for smart recipe generation.
- **To Monitor Health Metrics:** Track BMI and macro-nutrients.
- **To Streamline Grocery Management:** Auto-generate shopping lists.
- **To Enhance User Experience:** Provide modern UI (Deep Carbon theme).

---

### 5. Detailed System Modules & Functionalities

#### A. AI Recipe Recommendation Engine
- Core module powered by Google Gemini API
- **Workflow:**
  1. User selects ingredients
  2. Data sent to AI
  3. AI generates recipe
- **Output:** Cooking steps, time, difficulty, and nutrition

#### B. Smart Pantry Tracker
- Digital storage for kitchen items
- Users can add, edit, and manage ingredients
- *(Future)* Low-stock alerts for essential items

#### C. Nutrition & BMI Dashboard
- Health monitoring module
- **BMI Calculator:** Based on height and weight
- **Macro Tracker:** Protein, carbs, fat tracking

#### D. Interactive Meal Planner
- Calendar-based planning system
- Schedule meals (Breakfast, Lunch, Dinner)
- Syncs automatically with grocery list

---

### 6. System Architecture & Technology Stack
**Architecture:** Client–Server Architecture

**Technology Stack:**

| Layer | Technology |
| :--- | :--- |
| **Frontend** | Flutter 3.x (BloC / Provider) |
| **Backend** | PHP (REST API) |
| **AI Layer** | Google Gemini API |
| **Database** | MySQL + SharedPreferences |
| **Tools** | VS Code, XAMPP, Git |

---

### 8. Scope & Future Enhancements

**Current Scope:**
- AI Recipe Recommendation
- Pantry Management
- Nutrition Tracking

**Future Enhancements:**
- Social Feed (community sharing)
- Cloud Sync (Firebase integration)
- Voice Assistant for cooking guidance

---

### 9. Conclusion
The Food Recipe Recommendation Application (CookSmart) is more than just a recipe app—it is a complete smart kitchen solution.
By combining AI technology with practical tools, it helps users:
- Save time
- Reduce food waste
- Maintain a healthy lifestyle

It empowers users to become smarter and more efficient in their daily cooking routines.
