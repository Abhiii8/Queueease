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

if(empty($data->qr_data) || empty($data->org_id)) {
    http_response_code(400);
    echo json_encode(["message" => "Missing data. Required: qr_data, org_id"]);
    exit();
}

try {
    // We lock rows during verification to prevent double scanning
    $db->beginTransaction();

    $stmt = $db->prepare("
        SELECT b.booking_id, b.status, q.queue_id 
        FROM bookings b
        JOIN queues q ON b.queue_id = q.queue_id
        JOIN services s ON q.service_id = s.service_id
        JOIN departments d ON s.dept_id = d.dept_id
        JOIN branches br ON d.branch_id = br.branch_id
        WHERE b.qr_verification_id = :qr AND br.org_id = :org_id
        FOR UPDATE
    ");
    $stmt->execute([':qr' => $data->qr_data, ':org_id' => $data->org_id]);
    $booking = $stmt->fetch(PDO::FETCH_ASSOC);

    if(!$booking) {
        $db->rollBack();
        http_response_code(404);
        echo json_encode(["message" => "Invalid Ticket for this Organization."]);
        exit();
    }

    if($booking['status'] == 'COMPLETED') {
        $db->rollBack();
        http_response_code(400);
        echo json_encode(["message" => "This ticket has already been verified."]);
        exit();
    }

    if($booking['status'] == 'CANCELLED') {
        $db->rollBack();
        http_response_code(400);
        echo json_encode(["message" => "This ticket was cancelled."]);
        exit();
    }

    // Update booking to completed
    $upd = $db->prepare("UPDATE bookings SET status = 'COMPLETED' WHERE booking_id = ?");
    $upd->execute([$booking['booking_id']]);

    // Decrease total waiting in queue if they were still waiting
    if($booking['status'] == 'WAITING' || $booking['status'] == 'CALLED') {
        $q_upd = $db->prepare("UPDATE queues SET total_waiting = GREATEST(total_waiting - 1, 0) WHERE queue_id = ?");
        $q_upd->execute([$booking['queue_id']]);
        
        // Decrease people ahead for others
        $up_waiters = $db->prepare("UPDATE bookings SET people_ahead = GREATEST(people_ahead - 1, 0) WHERE queue_id = ? AND status = 'WAITING'");
        $up_waiters->execute([$booking['queue_id']]);
    }

    $db->commit();
    http_response_code(200);
    echo json_encode(["message" => "Ticket successfully verified!"]);

} catch (Exception $e) {
    if($db->inTransaction()) {
        $db->rollBack();
    }
    http_response_code(500);
    echo json_encode(["message" => "Verification failed."]);
}
?>
