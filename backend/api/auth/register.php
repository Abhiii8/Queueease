<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once '../../config/database.php';
include_once '../../models/User.php';
include_once '../../utils/jwt.php';

$database = new Database();
$db = $database->getConnection();

$user = new User($db);

$data = json_decode(file_get_contents("php://input"));

if(
    !empty($data->name) &&
    !empty($data->email) &&
    !empty($data->password)
){
    $user->name = $data->name;
    $user->email = $data->email;
    $user->phone = isset($data->phone) ? $data->phone : null;
    $user->password_hash = $data->password;
    $user->role = isset($data->role) ? $data->role : 'USER'; // Can be ORG_ADMIN if passing special key

    if($user->emailExists()){
        http_response_code(400);
        echo json_encode(array("message" => "Email already exists."));
        exit();
    }

    if($user->create()){
        http_response_code(201);
        echo json_encode(array("message" => "User was created."));
    }
    else{
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create user."));
    }
}
else{
    http_response_code(400);
    echo json_encode(array("message" => "Unable to create user. Data is incomplete."));
}
?>
