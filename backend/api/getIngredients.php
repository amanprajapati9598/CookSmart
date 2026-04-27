<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

include("../config/db.php");

$sql = "SELECT * FROM Ingredients ORDER BY Category, Name";
$result = $conn->query($sql);

$ingredients = [];
while($row = $result->fetch_assoc()){
    $ingredients[] = $row;
}
echo json_encode($ingredients);
?>
