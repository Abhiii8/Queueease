<?php
class Booking {
    private $conn;
    private $table_name = "bookings";

    public $booking_id;
    public $booking_reference;
    public $user_id;
    public $queue_id;
    public $token_number;
    public $numeric_token;
    public $status;
    public $estimated_waiting_time;
    public $people_ahead;
    public $qr_verification_id;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . " 
                  SET booking_reference=:booking_reference, user_id=:user_id, queue_id=:queue_id, 
                      token_number=:token_number, numeric_token=:numeric_token, status='WAITING', 
                      estimated_waiting_time=:estimated_waiting_time, people_ahead=:people_ahead, 
                      qr_verification_id=:qr_verification_id";
        
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(":booking_reference", $this->booking_reference);
        $stmt->bindParam(":user_id", $this->user_id);
        $stmt->bindParam(":queue_id", $this->queue_id);
        $stmt->bindParam(":token_number", $this->token_number);
        $stmt->bindParam(":numeric_token", $this->numeric_token);
        $stmt->bindParam(":estimated_waiting_time", $this->estimated_waiting_time);
        $stmt->bindParam(":people_ahead", $this->people_ahead);
        $stmt->bindParam(":qr_verification_id", $this->qr_verification_id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function readByUser() {
        $query = "SELECT b.*, s.name as service_name, s.token_prefix, o.name as org_name, br.name as branch_name, q.current_token_number
                  FROM " . $this->table_name . " b
                  JOIN queues q ON b.queue_id = q.queue_id
                  JOIN services s ON q.service_id = s.service_id
                  JOIN departments d ON s.dept_id = d.dept_id
                  JOIN branches br ON d.branch_id = br.branch_id
                  JOIN organizations o ON br.org_id = o.org_id
                  WHERE b.user_id = ? ORDER BY b.booked_at DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->user_id);
        $stmt->execute();
        return $stmt;
    }

    public function cancel() {
        $query = "UPDATE " . $this->table_name . " SET status = 'CANCELLED' WHERE booking_id = ? AND user_id = ? AND status = 'WAITING'";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->booking_id);
        $stmt->bindParam(2, $this->user_id);
        if($stmt->execute() && $stmt->rowCount() > 0) {
            return true;
        }
        return false;
    }
}
?>
