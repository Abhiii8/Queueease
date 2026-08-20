<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

include_once '../../config/database.php';
include_once '../../models/Queue.php';
include_once '../../models/Booking.php';
include_once '../../models/Service.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));
if(empty($data->service_id) || empty($data->user_id)) {
    http_response_code(400);
    echo json_encode(["message" => "Missing data."]);
    exit();
}

// Prevent user from having multiple active tickets for the same organization
$check_stmt = $db->prepare("
    SELECT COUNT(*) as count 
    FROM bookings b 
    JOIN queues q ON b.queue_id = q.queue_id 
    JOIN services s ON q.service_id = s.service_id
    JOIN departments d ON s.dept_id = d.dept_id
    JOIN branches br ON d.branch_id = br.branch_id
    WHERE b.user_id = ? 
    AND b.status IN ('WAITING', 'CALLED', 'SERVING')
    AND br.org_id = (
        SELECT br2.org_id 
        FROM services s2
        JOIN departments d2 ON s2.dept_id = d2.dept_id
        JOIN branches br2 ON d2.branch_id = br2.branch_id
        WHERE s2.service_id = ?
    )
");
$check_stmt->execute([$data->user_id, $data->service_id]);
$active_count = $check_stmt->fetch(PDO::FETCH_ASSOC)['count'];

if ($active_count > 0) {
    http_response_code(400);
    echo json_encode(["message" => "You already have an active ticket for this organization."]);
    exit();
}


try {
    $db->beginTransaction();

    // 1. Get or create Queue
    $queue = new Queue($db);
    $queue->service_id = $data->service_id;
    if(!$queue->getActiveQueue()) {
        $queue->createTodayQueue();
    }

    if($queue->status != 'OPEN') {
        throw new Exception("Queue is currently closed.");
    }

    // 2. Lock for token generation using row-level locking
    $db->prepare("SELECT * FROM queues WHERE queue_id = ? FOR UPDATE")->execute([$queue->queue_id]);
    
    // Refresh queue state after lock
    $queue->getActiveQueue();
    
    $new_token_numeric = $queue->last_issued_token + 1;
    $people_ahead = $new_token_numeric - $queue->current_token_number - 1;
    if($people_ahead < 0) $people_ahead = 0;

    // Get service info for token prefix & wait time
    $stmt = $db->prepare("SELECT token_prefix, average_service_time FROM services WHERE service_id = ?");
    $stmt->execute([$data->service_id]);
    $service_row = $stmt->fetch(PDO::FETCH_ASSOC);
    $prefix = $service_row['token_prefix'] ?? 'A';
    $avg_time = $service_row['average_service_time'] ?? 5;
    
    $token_str = $prefix . "-" . str_pad($new_token_numeric, 3, "0", STR_PAD_LEFT);
    $estimated_wait = $people_ahead * $avg_time;

    // 3. Create Booking
    $booking = new Booking($db);
    $booking->booking_reference = "REF-" . time() . "-" . rand(1000, 9999);
    $booking->user_id = $data->user_id;
    $booking->queue_id = $queue->queue_id;
    $booking->token_number = $token_str;
    $booking->numeric_token = $new_token_numeric;
    $booking->estimated_waiting_time = $estimated_wait;
    $booking->people_ahead = $people_ahead;
    $booking->qr_verification_id = md5($booking->booking_reference . $data->user_id);

    if($booking->create()) {
        // Update Queue
        $updateQ = "UPDATE queues SET last_issued_token = ?, total_waiting = total_waiting + 1 WHERE queue_id = ?";
        $qstmt = $db->prepare($updateQ);
        $qstmt->execute([$new_token_numeric, $queue->queue_id]);
        
        $db->commit();
        
        http_response_code(201);
        echo json_encode([
            "message" => "Token booked successfully",
            "token_number" => $token_str,
            "people_ahead" => $people_ahead,
            "estimated_waiting_time" => $estimated_wait,
            "booking_reference" => $booking->booking_reference,
            "qr_data" => $booking->qr_verification_id
        ]);
    } else {
        throw new Exception("Could not create booking");
    }

} catch (Exception $e) {
    if($db->inTransaction()) {
        $db->rollBack();
    }
    http_response_code(500);
    echo json_encode(["message" => $e->getMessage()]);
}
?>
