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

$user->email = isset($data->email) ? $data->email : "";
$email_exists = $user->emailExists();

if($email_exists && password_verify($data->password, $user->password_hash)){
    $token_payload = array(
        "iss" => "queueease.com",
        "iat" => time(),
        "exp" => time() + (60 * 60 * 24 * 7), // 7 days
        "data" => array(
            "user_id" => $user->user_id,
            "name" => $user->name,
            "email" => $user->email,
            "role" => $user->role
        )
    );

    $jwt = JWT::encode($token_payload);
    
    http_response_code(200);
    echo json_encode(
            array(
                "message" => "Successful login.",
                "jwt" => $jwt,
                "user" => $token_payload['data']
            )
        );
}
else{
    http_response_code(401);
    echo json_encode(array("message" => "Login failed. Invalid email or password."));
}
?>
