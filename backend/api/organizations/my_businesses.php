<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : die();

$query = "SELECT * FROM organizations WHERE admin_id = :user_id ORDER BY created_at DESC";
$stmt = $db->prepare($query);
$stmt->bindParam(":user_id", $user_id);
$stmt->execute();

$num = $stmt->rowCount();

if($num > 0) {
    $orgs_arr = array();
    $orgs_arr["records"] = array();

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)){
        extract($row);
        $org_item = array(
            "org_id" => $org_id,
            "name" => $name,
            "category" => $category,
            "description" => html_entity_decode($description),
            "status" => $status,
            "logo_url" => $logo_url
        );
        array_push($orgs_arr["records"], $org_item);
    }
    http_response_code(200);
    echo json_encode($orgs_arr);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "No businesses found."));
}
?>
