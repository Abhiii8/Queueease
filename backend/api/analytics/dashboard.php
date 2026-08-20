<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$org_id = isset($_GET['org_id']) ? $_GET['org_id'] : die(json_encode(["message" => "Missing org_id."]));

// Get today's date bounds
$today_start = date('Y-m-d 00:00:00');
$today_end = date('Y-m-d 23:59:59');

$response = [
    "total_visitors_today" => 0,
    "avg_wait_time_minutes" => 0,
    "peak_hours" => []
];

try {
    // 1. Total visitors today
    $query_total = "
        SELECT COUNT(b.booking_id) as total
        FROM bookings b
        JOIN queues q ON b.queue_id = q.queue_id
        JOIN services s ON q.service_id = s.service_id
        JOIN departments d ON s.dept_id = d.dept_id
        JOIN branches br ON d.branch_id = br.branch_id
        WHERE br.org_id = :org_id 
        AND b.booked_at >= :today_start AND b.booked_at <= :today_end
    ";
    $stmt_total = $db->prepare($query_total);
    $stmt_total->execute(['org_id' => $org_id, 'today_start' => $today_start, 'today_end' => $today_end]);
    $row_total = $stmt_total->fetch(PDO::FETCH_ASSOC);
    $response["total_visitors_today"] = (int)$row_total['total'];

    // 2. Average Wait Time (for completed or serving bookings today)
    // Assuming 'updated_at' is set when status changes to COMPLETED or SERVING
    // We can also just take CALLED, SERVING, COMPLETED
    $query_wait = "
        SELECT AVG(TIMESTAMPDIFF(MINUTE, b.booked_at, b.updated_at)) as avg_wait
        FROM bookings b
        JOIN queues q ON b.queue_id = q.queue_id
        JOIN services s ON q.service_id = s.service_id
        JOIN departments d ON s.dept_id = d.dept_id
        JOIN branches br ON d.branch_id = br.branch_id
        WHERE br.org_id = :org_id
        AND b.status IN ('CALLED', 'SERVING', 'COMPLETED')
        AND b.booked_at >= :today_start AND b.booked_at <= :today_end
    ";
    $stmt_wait = $db->prepare($query_wait);
    $stmt_wait->execute(['org_id' => $org_id, 'today_start' => $today_start, 'today_end' => $today_end]);
    $row_wait = $stmt_wait->fetch(PDO::FETCH_ASSOC);
    $response["avg_wait_time_minutes"] = $row_wait['avg_wait'] ? round((float)$row_wait['avg_wait']) : 0;

    // 3. Peak Hours
    $query_peak = "
        SELECT HOUR(b.booked_at) as hour, COUNT(b.booking_id) as count
        FROM bookings b
        JOIN queues q ON b.queue_id = q.queue_id
        JOIN services s ON q.service_id = s.service_id
        JOIN departments d ON s.dept_id = d.dept_id
        JOIN branches br ON d.branch_id = br.branch_id
        WHERE br.org_id = :org_id
        AND b.booked_at >= :today_start AND b.booked_at <= :today_end
        GROUP BY HOUR(b.booked_at)
        ORDER BY hour ASC
    ";
    $stmt_peak = $db->prepare($query_peak);
    $stmt_peak->execute(['org_id' => $org_id, 'today_start' => $today_start, 'today_end' => $today_end]);
    
    // Initialize hours from 8 AM to 8 PM (08 to 20) with 0
    $hours_data = [];
    for($i = 8; $i <= 20; $i++) {
        $hours_data[$i] = 0;
    }

    while ($row = $stmt_peak->fetch(PDO::FETCH_ASSOC)) {
        $h = (int)$row['hour'];
        // Only include if it's within business hours for the chart, or just add it
        if(isset($hours_data[$h])) {
            $hours_data[$h] = (int)$row['count'];
        }
    }

    // Format for frontend array of objects {hour: 8, count: 5}
    foreach($hours_data as $h => $c) {
        $response["peak_hours"][] = [
            "hour" => $h,
            "count" => $c
        ];
    }

    http_response_code(200);
    echo json_encode($response);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => $e->getMessage()]);
}
?>
