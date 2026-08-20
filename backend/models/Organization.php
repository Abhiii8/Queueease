<?php
class Organization {
    private $conn;
    private $table_name = "organizations";

    public $org_id;
    public $name;
    public $category;
    public $description;
    public $logo_url;
    public $contact_number;
    public $email;
    public $status;
    public $admin_id;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function read() {
        $query = "SELECT * FROM " . $this->table_name . " WHERE status = 'ACTIVE' ORDER BY name ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function readOne() {
        $query = "SELECT * FROM " . $this->table_name . " WHERE org_id = ? LIMIT 0,1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->org_id);
        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if($row) {
            $this->name = $row['name'];
            $this->category = $row['category'];
            $this->description = $row['description'];
            $this->logo_url = $row['logo_url'];
            return true;
        }
        return false;
    }
}
?>
