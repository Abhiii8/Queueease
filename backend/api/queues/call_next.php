<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once '../../config/database.php';
include_once '../../models/Queue.php';
include_once '../../models/Booking.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if(empty($data->service_id)) {
    http_response_code(400);
    echo json_encode(["message" => "Missing service_id."]);
    exit();
}

$queue = new Queue($db);
$queue->service_id = $data->service_id;

if(!$queue->getActiveQueue()) {
    http_response_code(404);
    echo json_encode(["message" => "No active queue found."]);
    exit();
}

try {
    $db->beginTransaction();

    // Find the oldest WAITING booking for this queue
    $stmt = $db->prepare("SELECT * FROM bookings WHERE queue_id = ? AND status = 'WAITING' ORDER BY numeric_token ASC LIMIT 1 FOR UPDATE");
    $stmt->execute([$queue->queue_id]);
    
    if ($stmt->rowCount() == 0) {
        $db->rollBack();
        http_response_code(404);
        echo json_encode(["message" => "No waiting tickets found."]);
        exit();
    }

    $booking_row = $stmt->fetch(PDO::FETCH_ASSOC);
    $booking_id = $booking_row['booking_id'];
    $called_token = $booking_row['token_number'];
    $numeric_token = $booking_row['numeric_token'];

    // Update booking status to CALLED
    $update_booking = $db->prepare("UPDATE bookings SET status = 'CALLED' WHERE booking_id = ?");
    $update_booking->execute([$booking_id]);

    // Update queue current token
    $update_queue = $db->prepare("UPDATE queues SET current_token_number = ?, total_waiting = total_waiting - 1 WHERE queue_id = ?");
    $update_queue->execute([$numeric_token, $queue->queue_id]);

    // Also update all other waiting bookings to reduce people_ahead and estimated_wait
    // This is optional but good for real-time accuracy, although we can just calculate it dynamically.
    // For now, we just decrement people_ahead.
    $update_others = $db->prepare("UPDATE bookings SET people_ahead = GREATEST(0, people_ahead - 1) WHERE queue_id = ? AND status = 'WAITING'");
    $update_others->execute([$queue->queue_id]);

    $db->commit();

    http_response_code(200);
    echo json_encode([
        "message" => "Successfully called next token.",
        "called_token" => $called_token
    ]);

} catch (Exception $e) {
    if($db->inTransaction()) {
        $db->rollBack();
    }
    http_response_code(500);
    echo json_encode(["message" => $e->getMessage()]);
}
?>
