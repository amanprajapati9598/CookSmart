<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

include("../config/db.php");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['name']) || !isset($input['email']) || !isset($input['password'])) {
    echo json_encode(['success' => false, 'message' => 'Name, Email, and Password are required']);
    exit();
}

$name = $conn->real_escape_string($input['name']);
$email = $conn->real_escape_string($input['email']);
$password = password_hash($input['password'], PASSWORD_DEFAULT);

$sql = "INSERT INTO Users (Name, Email, Password) VALUES ('$name', '$email', '$password')";

try {
    if ($conn->query($sql) === TRUE) {
        echo json_encode(['success' => true, 'message' => 'User Registered', 'user' => [
            'User_ID' => $conn->insert_id,
            'Name' => $name,
            'Email' => $email
        ]]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Email already exists or a database error occurred']);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Email already exists or a database error occurred: ' . $e->getMessage()]);
}
?>