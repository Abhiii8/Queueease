<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

include_once '../../config/database.php';
include_once '../../models/Queue.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));
if(empty($data->queue_id) || empty($data->action)) {
    http_response_code(400);
    echo json_encode(["message" => "Missing data. Required: queue_id, action (CALL_NEXT, COMPLETE, SKIP)"]);
    exit();
}

// In a real app, verify Admin JWT token here

try {
    $db->beginTransaction();

    // Get current queue state
    $stmt = $db->prepare("SELECT * FROM queues WHERE queue_id = ? FOR UPDATE");
    $stmt->execute([$data->queue_id]);
    $q = $stmt->fetch(PDO::FETCH_ASSOC);

    if(!$q) throw new Exception("Queue not found.");

    if($data->action === 'CALL_NEXT') {
        // Find next waiting booking
        $b_stmt = $db->prepare("SELECT * FROM bookings WHERE queue_id = ? AND status = 'WAITING' ORDER BY numeric_token ASC LIMIT 1");
        $b_stmt->execute([$data->queue_id]);
        $next_b = $b_stmt->fetch(PDO::FETCH_ASSOC);

        if($next_b) {
            // Update queue current token
            $upq = $db->prepare("UPDATE queues SET current_token_number = ?, total_waiting = total_waiting - 1 WHERE queue_id = ?");
            $upq->execute([$next_b['numeric_token'], $data->queue_id]);

            // Update booking status
            $upb = $db->prepare("UPDATE bookings SET status = 'CALLED' WHERE booking_id = ?");
            $upb->execute([$next_b['booking_id']]);
            
            // Also update people ahead for remaining bookings in this queue
            $up_waiters = $db->prepare("UPDATE bookings SET people_ahead = GREATEST(people_ahead - 1, 0) WHERE queue_id = ? AND status = 'WAITING'");
            $up_waiters->execute([$data->queue_id]);

            echo json_encode(["message" => "Queue advanced.", "called_token" => $next_b['token_number']]);
        } else {
            echo json_encode(["message" => "No more waiting tokens."]);
        }
    } 
    // Add logic for COMPLETE, SKIP here...
    
    $db->commit();
    http_response_code(200);

} catch (Exception $e) {
    if($db->inTransaction()) {
        $db->rollBack();
    }
    http_response_code(500);
    echo json_encode(["message" => $e->getMessage()]);
}
?>
