<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once '../../config/database.php';
include_once '../../models/Booking.php';

$database = new Database();
$db = $database->getConnection();

$booking = new Booking($db);
$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : die();
$booking->user_id = $user_id;

$stmt = $booking->readByUser();
$num = $stmt->rowCount();

if($num > 0) {
    $bookings_arr = array();
    $bookings_arr["records"] = array();

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)){
        extract($row);
        
        // Dynamic wait time calculation (just simple math for demo)
        $current_people_ahead = max(0, $numeric_token - $current_token_number);
        if($status != 'WAITING' && $status != 'BOOKED') {
            $current_people_ahead = 0;
        }

        $b_item = array(
            "booking_id" => $booking_id,
            "booking_reference" => $booking_reference,
            "token_number" => $token_number,
            "status" => $status,
            "people_ahead" => $current_people_ahead,
            "estimated_waiting_time" => $estimated_waiting_time,
            "qr_verification_id" => $qr_verification_id,
            "booked_at" => $booked_at,
            "service_name" => $service_name,
            "branch_name" => $branch_name,
            "org_name" => $org_name,
            "current_queue_token" => $current_token_number
        );
        array_push($bookings_arr["records"], $b_item);
    }
    http_response_code(200);
    echo json_encode($bookings_arr);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "No bookings found."));
}
?>
