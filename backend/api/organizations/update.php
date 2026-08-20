<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

// Since we are handling file uploads, we cannot use php://input exclusively.
// We check $_POST for form-data, or fallback to php://input if it's sent as JSON (without file).
$is_json = false;
$data = json_decode(file_get_contents("php://input"));
if ($data) {
    $is_json = true;
    $_POST['org_id'] = $data->org_id ?? null;
    $_POST['user_id'] = $data->user_id ?? null;
    $_POST['name'] = $data->name ?? null;
    $_POST['category'] = $data->category ?? null;
    $_POST['description'] = $data->description ?? null;
    $_POST['allows_scheduling'] = $data->allows_scheduling ?? 0;
}

if(
    !empty($_POST['org_id']) &&
    !empty($_POST['user_id']) &&
    !empty($_POST['name']) &&
    !empty($_POST['category'])
){
    try {
        $org_id = (int) $_POST['org_id'];
        $user_id = (int) $_POST['user_id'];
        
        // Security check: ensure user_id is the admin of this org
        $checkQuery = "SELECT admin_id FROM organizations WHERE org_id = :org_id";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->bindParam(":org_id", $org_id);
        $checkStmt->execute();
        
        if($checkStmt->rowCount() == 0) {
            http_response_code(404);
            echo json_encode(array("message" => "Organization not found."));
            exit();
        }
        
        $orgRow = $checkStmt->fetch(PDO::FETCH_ASSOC);
        if($orgRow['admin_id'] != $user_id) {
            http_response_code(403);
            echo json_encode(array("message" => "Unauthorized access."));
            exit();
        }

        // Handle Image Upload
        $logo_url = null;
        if(isset($_FILES['photo']) && $_FILES['photo']['error'] == UPLOAD_ERR_OK) {
            $upload_dir = '../../uploads/organizations/';
            
            // Create directory if it doesn't exist
            if (!is_dir($upload_dir)) {
                mkdir($upload_dir, 0777, true);
            }
            
            $file_ext = strtolower(pathinfo($_FILES['photo']['name'], PATHINFO_EXTENSION));
            $allowed_exts = array('jpg', 'jpeg', 'png', 'gif', 'webp');
            
            if(in_array($file_ext, $allowed_exts)) {
                // Generate a unique filename
                $new_filename = uniqid('org_' . $org_id . '_') . '.' . $file_ext;
                $target_path = $upload_dir . $new_filename;
                
                if(move_uploaded_file($_FILES['photo']['tmp_name'], $target_path)) {
                    // Save relative path for easy access
                    $logo_url = 'backend/uploads/organizations/' . $new_filename;
                }
            }
        }

        // Build Update Query
        $updateQuery = "UPDATE organizations SET 
                        name = :name, 
                        category = :category, 
                        description = :description, 
                        allows_scheduling = :allows_scheduling";
                        
        if($logo_url != null) {
            $updateQuery .= ", logo_url = :logo_url";
        }
        
        $updateQuery .= " WHERE org_id = :org_id";
        
        $stmt = $db->prepare($updateQuery);

        $name = htmlspecialchars(strip_tags($_POST['name']));
        $category = htmlspecialchars(strip_tags($_POST['category']));
        $description = isset($_POST['description']) ? htmlspecialchars(strip_tags($_POST['description'])) : null;
        $allows_scheduling = isset($_POST['allows_scheduling']) ? (int)$_POST['allows_scheduling'] : 0;

        $stmt->bindParam(":name", $name);
        $stmt->bindParam(":category", $category);
        $stmt->bindParam(":description", $description);
        $stmt->bindParam(":allows_scheduling", $allows_scheduling);
        $stmt->bindParam(":org_id", $org_id);
        
        if($logo_url != null) {
            $stmt->bindParam(":logo_url", $logo_url);
        }

        if($stmt->execute()) {
            http_response_code(200);
            echo json_encode(array(
                "message" => "Organization updated successfully.",
                "logo_url" => $logo_url
            ));
        } else {
            http_response_code(503);
            echo json_encode(array("message" => "Unable to update organization."));
        }
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(array("message" => "Database error: " . $e->getMessage()));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete data. Name, category, org_id, and user_id are required."));
}
?>
