<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once '../../config/database.php';
include_once '../../models/Service.php';

$database = new Database();
$db = $database->getConnection();

$service = new Service($db);

$branch_id = isset($_GET['branch_id']) ? $_GET['branch_id'] : die();
$service->branch_id = $branch_id;

$stmt = $service->readByBranchId();
$num = $stmt->rowCount();

if($num > 0) {
    $services_arr = array();
    $services_arr["records"] = array();

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)){
        extract($row);
        $service_item = array(
            "service_id" => $service_id,
            "dept_id" => $dept_id,
            "department_name" => $department_name,
            "name" => $name,
            "description" => $description,
            "average_service_time" => $average_service_time,
            "token_prefix" => $token_prefix
        );
        array_push($services_arr["records"], $service_item);
    }
    http_response_code(200);
    echo json_encode($services_arr);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "No services found."));
}
?>
