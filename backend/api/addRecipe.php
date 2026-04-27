<?php

include("../config/db.php");

$data = json_decode(file_get_contents("php://input"));

$title = $data->title;
$instructions = $data->instructions;
$time = $data->cooking_time;

$sql = "INSERT INTO recipes(title,instructions,cooking_time)
VALUES('$title','$instructions','$time')";

if($conn->query($sql)){
echo json_encode(["message"=>"Recipe Added"]);
}

?>