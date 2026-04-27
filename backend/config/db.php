<?php

try {
    $conn = new mysqli("localhost", "root", "", "receipe_db");
    
    if($conn->connect_error){
        echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $conn->connect_error]);
        exit();
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $e->getMessage()]);
    exit();
}

?>