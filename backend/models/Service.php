<?php
class Service {
    private $conn;
    private $table_name = "services";
    private $dept_table = "departments";

    public $service_id;
    public $dept_id;
    public $name;
    public $description;
    public $average_service_time;
    public $branch_id; // For joining

    public function __construct($db) {
        $this->conn = $db;
    }

    public function readByBranchId() {
        // Join with departments to get services for a specific branch
        $query = "SELECT s.*, d.name as department_name 
                  FROM " . $this->table_name . " s
                  JOIN " . $this->dept_table . " d ON s.dept_id = d.dept_id
                  WHERE d.branch_id = ? AND s.status = 'ACTIVE' AND d.status = 'ACTIVE'
                  ORDER BY d.name, s.name ASC";
                  
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->branch_id);
        $stmt->execute();
        return $stmt;
    }
}
?>
