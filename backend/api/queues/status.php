<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once '../../config/database.php';
include_once '../../models/Queue.php';
include_once '../../models/Service.php';

$database = new Database();
$db = $database->getConnection();

$service_id = isset($_GET['service_id']) ? $_GET['service_id'] : die();

$queue = new Queue($db);
$queue->service_id = $service_id;

if($queue->getActiveQueue()) {
    
    // Get Service details
    $stmt = $db->prepare("SELECT name, average_service_time FROM services WHERE service_id = ?");
    $stmt->execute([$service_id]);
    $srv = $stmt->fetch(PDO::FETCH_ASSOC);

    $queue_arr = [
        "queue_id" => $queue->queue_id,
        "service_name" => $srv['name'],
        "current_token_number" => $queue->current_token_number,
        "last_issued_token" => $queue->last_issued_token,
        "status" => $queue->status,
        "total_waiting" => $queue->total_waiting,
        "average_service_time" => $srv['average_service_time']
    ];
    http_response_code(200);
    echo json_encode($queue_arr);
} else {
    // Get Service details even if queue hasn't been created yet today
    $stmt = $db->prepare("SELECT name, average_service_time FROM services WHERE service_id = ?");
    $stmt->execute([$service_id]);
    if ($stmt->rowCount() > 0) {
        $srv = $stmt->fetch(PDO::FETCH_ASSOC);
        $queue_arr = [
            "queue_id" => null,
            "service_name" => $srv['name'],
            "current_token_number" => 0,
            "last_issued_token" => 0,
            "status" => 'OPEN',
            "total_waiting" => 0,
            "average_service_time" => $srv['average_service_time']
        ];
        http_response_code(200);
        echo json_encode($queue_arr);
    } else {
        http_response_code(404);
        echo json_encode(["message" => "Service not found."]);
    }
}
?>
