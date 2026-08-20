<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : die();

$query = "
    SELECT b.booking_id, b.token_number, b.estimated_waiting_time, b.status,
           q.current_token_number, s.name as service_name, org.name as org_name
    FROM bookings b
    JOIN queues q ON b.queue_id = q.queue_id
    JOIN services s ON q.service_id = s.service_id
    JOIN departments d ON s.dept_id = d.dept_id
    JOIN branches br ON d.branch_id = br.branch_id
    JOIN organizations org ON br.org_id = org.org_id
    WHERE b.user_id = :user_id 
      AND (b.status = 'WAITING' OR b.status = 'CALLED')
    ORDER BY b.booked_at DESC
    LIMIT 1
";

$stmt = $db->prepare($query);
$stmt->bindParam(":user_id", $user_id);
$stmt->execute();

$active_booking = $stmt->fetch(PDO::FETCH_ASSOC);

if($active_booking) {
    http_response_code(200);
    echo json_encode($active_booking);
} else {
    http_response_code(404);
    echo json_encode(["message" => "No active booking found."]);
}
?>
