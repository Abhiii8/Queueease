<?php
class Branch {
    private $conn;
    private $table_name = "branches";

    public $branch_id;
    public $org_id;
    public $name;
    public $address;
    public $city;
    public $status;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function readByOrgId() {
        $query = "SELECT * FROM " . $this->table_name . " WHERE org_id = ? AND status = 'ACTIVE' ORDER BY name ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->org_id);
        $stmt->execute();
        return $stmt;
    }
}
?>
