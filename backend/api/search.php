<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

include("../config/db.php");

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$input = json_decode(file_get_contents('php://input'), true);
$user_ingredients = isset($input['ingredients']) ? $input['ingredients'] : [];

if (empty($user_ingredients)) {
    echo json_encode(['error' => 'No ingredients provided']);
    exit();
}

// Sanitize user ingredients to integers
$user_ingredients = array_map('intval', $user_ingredients);
$in_clause = implode(',', $user_ingredients);

$sql = "
SELECT 
    r.Recipe_ID, r.Title, r.Instructions, r.Cooking_Time, r.Calories, r.Difficulty_Level, r.Is_Veg, r.Image_URL,
    (SELECT COUNT(*) FROM Recipe_Ingredients ri WHERE ri.Recipe_ID = r.Recipe_ID) AS Total_Ingredients,
    (SELECT COUNT(*) FROM Recipe_Ingredients ri WHERE ri.Recipe_ID = r.Recipe_ID AND ri.Ingredient_ID IN ($in_clause)) AS Matched_Ingredients
FROM Recipes r
HAVING Matched_Ingredients > 0
ORDER BY Matched_Ingredients DESC, Total_Ingredients ASC
";

$result = $conn->query($sql);
$recipes = [];

while($row = $result->fetch_assoc()){
    if ($row['Matched_Ingredients'] == 0) continue; // safety check
    
    // Find missing ingredients
    $recipe_id = intval($row['Recipe_ID']);
    $missing_sql = "
        SELECT i.Name, i.Substitutes 
        FROM Recipe_Ingredients ri 
        JOIN Ingredients i ON ri.Ingredient_ID = i.Ingredient_ID
        WHERE ri.Recipe_ID = $recipe_id 
        AND i.Ingredient_ID NOT IN ($in_clause)
    ";
    
    $missing_result = $conn->query($missing_sql);
    $missing_ingredients = [];
    while($m_row = $missing_result->fetch_assoc()) {
        $missing_ingredients[] = $m_row;
    }
    
    $row['Missing_Ingredients'] = $missing_ingredients;
    
    // If we only have missing 1-2 ingredients or enough matched
    $recipes[] = $row;
}

echo json_encode(['success' => true, 'data' => $recipes]);
?>
