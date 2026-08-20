<?php
class Queue {
    private $conn;
    private $table_name = "queues";

    public $queue_id;
    public $service_id;
    public $queue_date;
    public $current_token_number;
    public $last_issued_token;
    public $status;
    public $total_waiting;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function getActiveQueue() {
        $this->queue_date = date('Y-m-d');
        $query = "SELECT * FROM " . $this->table_name . " 
                  WHERE service_id = ? AND queue_date = ? LIMIT 0,1";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->service_id);
        $stmt->bindParam(2, $this->queue_date);
        $stmt->execute();
        
        if($stmt->rowCount() > 0) {
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $this->queue_id = $row['queue_id'];
            $this->current_token_number = $row['current_token_number'];
            $this->last_issued_token = $row['last_issued_token'];
            $this->status = $row['status'];
            $this->total_waiting = $row['total_waiting'];
            return true;
        }
        return false;
    }

    public function createTodayQueue() {
        $this->queue_date = date('Y-m-d');
        $query = "INSERT IGNORE INTO " . $this->table_name . " 
                  SET service_id = :service_id, queue_date = :queue_date, status = 'OPEN'";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':service_id', $this->service_id);
        $stmt->bindParam(':queue_date', $this->queue_date);
        if($stmt->execute()) {
            return $this->getActiveQueue(); // load properties
        }
        return false;
    }

    public function updateWaitingCount() {
        $query = "UPDATE " . $this->table_name . " SET total_waiting = (SELECT COUNT(*) FROM bookings WHERE queue_id = ? AND status = 'WAITING') WHERE queue_id = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->queue_id);
        $stmt->bindParam(2, $this->queue_id);
        $stmt->execute();
    }
}
?>
