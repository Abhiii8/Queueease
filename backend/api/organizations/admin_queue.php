<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$org_id = isset($_GET['org_id']) ? $_GET['org_id'] : die();
$date = date("Y-m-d");

// Find the active queue for this organization today
$query = "
    SELECT q.*, s.name as service_name, s.token_prefix 
    FROM queues q
    JOIN services s ON q.service_id = s.service_id
    JOIN departments d ON s.dept_id = d.dept_id
    JOIN branches b ON d.branch_id = b.branch_id
    WHERE b.org_id = :org_id AND q.queue_date = :qdate AND q.status = 'OPEN'
    LIMIT 1
";

$stmt = $db->prepare($query);
$stmt->bindParam(":org_id", $org_id);
$stmt->bindParam(":qdate", $date);
$stmt->execute();

$queue = $stmt->fetch(PDO::FETCH_ASSOC);

if(!$queue) {
    http_response_code(404);
    echo json_encode(array("message" => "No active queue found for today."));
    exit();
}

// Fetch waiting list
$wait_query = "
    SELECT b.booking_id, b.token_number, b.numeric_token, b.booked_at, u.name as user_name
    FROM bookings b
    JOIN users u ON b.user_id = u.user_id
    WHERE b.queue_id = :qid AND b.status = 'WAITING'
    ORDER BY b.numeric_token ASC
";

$wait_stmt = $db->prepare($wait_query);
$wait_stmt->bindParam(":qid", $queue['queue_id']);
$wait_stmt->execute();

$waiting_list = array();
while ($row = $wait_stmt->fetch(PDO::FETCH_ASSOC)) {
    array_push($waiting_list, $row);
}

http_response_code(200);
echo json_encode(array(
    "queue" => $queue,
    "waiting_list" => $waiting_list
));
?>
