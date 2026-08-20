<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if(
    !empty($data->org_id) &&
    !empty($data->user_id)
){
    // Verify ownership and delete
    $query = "DELETE FROM organizations WHERE org_id = :org_id AND admin_id = :user_id";
    $stmt = $db->prepare($query);

    $stmt->bindParam(":org_id", $data->org_id);
    $stmt->bindParam(":user_id", $data->user_id);

    if($stmt->execute()) {
        if ($stmt->rowCount() > 0) {
            http_response_code(200);
            echo json_encode(array("message" => "Organization deleted successfully."));
        } else {
            http_response_code(403);
            echo json_encode(array("message" => "Unauthorized or organization not found."));
        }
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to delete organization."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete data."));
}
?>
