<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once '../../config/database.php';
include_once '../../models/Branch.php';

$database = new Database();
$db = $database->getConnection();

$branch = new Branch($db);

$org_id = isset($_GET['org_id']) ? $_GET['org_id'] : die();
$branch->org_id = $org_id;

$stmt = $branch->readByOrgId();
$num = $stmt->rowCount();

if($num > 0) {
    $branches_arr = array();
    $branches_arr["records"] = array();

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)){
        extract($row);
        $branch_item = array(
            "branch_id" => $branch_id,
            "org_id" => $org_id,
            "name" => $name,
            "address" => $address,
            "city" => $city
        );
        array_push($branches_arr["records"], $branch_item);
    }
    http_response_code(200);
    echo json_encode($branches_arr);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "No branches found."));
}
?>
