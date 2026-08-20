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
$is_json = false;
$data = json_decode(file_get_contents("php://input"));
if ($data) {
    $is_json = true;
    $_POST['name'] = $data->name ?? null;
    $_POST['category'] = $data->category ?? null;
    $_POST['description'] = $data->description ?? null;
    $_POST['branch_name'] = $data->branch_name ?? null;
    $_POST['allows_scheduling'] = $data->allows_scheduling ?? 0;
    $_POST['user_id'] = $data->user_id ?? null;
}

if(
    !empty($_POST['name']) &&
    !empty($_POST['category']) &&
    !empty($_POST['user_id'])
){
    try {
        $db->beginTransaction();

        $name = htmlspecialchars(strip_tags($_POST['name']));
        $category = htmlspecialchars(strip_tags($_POST['category']));
        $description = isset($_POST['description']) ? htmlspecialchars(strip_tags($_POST['description'])) : null;
        $allows_scheduling = isset($_POST['allows_scheduling']) ? (int)$_POST['allows_scheduling'] : 0;
        $user_id = (int) $_POST['user_id'];

        // 1. Insert Organization
        $query = "INSERT INTO organizations (name, category, description, allows_scheduling, admin_id, status) VALUES (:name, :category, :description, :allows_scheduling, :admin_id, 'ACTIVE')";
        $stmt = $db->prepare($query);

        $stmt->bindParam(":name", $name);
        $stmt->bindParam(":category", $category);
        $stmt->bindParam(":description", $description);
        $stmt->bindParam(":allows_scheduling", $allows_scheduling);
        $stmt->bindParam(":admin_id", $user_id);

        if($stmt->execute()) {
            $org_id = $db->lastInsertId();

            // Handle Image Upload
            $logo_url = null;
            if(isset($_FILES['photo']) && $_FILES['photo']['error'] == UPLOAD_ERR_OK) {
                $upload_dir = '../../uploads/organizations/';
                if (!is_dir($upload_dir)) {
                    mkdir($upload_dir, 0777, true);
                }
                $file_ext = strtolower(pathinfo($_FILES['photo']['name'], PATHINFO_EXTENSION));
                $allowed_exts = array('jpg', 'jpeg', 'png', 'gif', 'webp');
                if(in_array($file_ext, $allowed_exts)) {
                    $new_filename = uniqid('org_' . $org_id . '_') . '.' . $file_ext;
                    $target_path = $upload_dir . $new_filename;
                    if(move_uploaded_file($_FILES['photo']['tmp_name'], $target_path)) {
                        $logo_url = 'backend/uploads/organizations/' . $new_filename;
                        // Update the org with the logo
                        $updateLogoQuery = "UPDATE organizations SET logo_url = :logo_url WHERE org_id = :org_id";
                        $logoStmt = $db->prepare($updateLogoQuery);
                        $logoStmt->bindParam(":logo_url", $logo_url);
                        $logoStmt->bindParam(":org_id", $org_id);
                        $logoStmt->execute();
                    }
                }
            }

            // Auto-Seed Default Branch, Department, Service, and Queue
            $branch_name = !empty($_POST['branch_name']) ? htmlspecialchars(strip_tags($_POST['branch_name'])) : 'Main Branch';
            $db->exec("INSERT INTO branches (org_id, name, address, status) VALUES ($org_id, '$branch_name', 'Primary Location', 'ACTIVE')");
            $branch_id = $db->lastInsertId();

            $db->exec("INSERT INTO departments (branch_id, name, description, status) VALUES ($branch_id, 'General Department', 'Default Dept', 'ACTIVE')");
            $dept_id = $db->lastInsertId();

            $db->exec("INSERT INTO services (dept_id, name, description, token_prefix, average_service_time, status) VALUES ($dept_id, 'General Consultation', 'Walk-in services', 'A', 5, 'ACTIVE')");
            $service_id = $db->lastInsertId();

            $date = date("Y-m-d");
            $db->exec("INSERT INTO queues (service_id, queue_date, status) VALUES ($service_id, '$date', 'OPEN')");

            // 2. Upgrade user to ORG_ADMIN if they aren't already
            $updateUser = "UPDATE users SET role = 'ORG_ADMIN' WHERE user_id = :user_id AND role = 'USER'";
            $stmtUser = $db->prepare($updateUser);
            $stmtUser->bindParam(":user_id", $user_id);
            $stmtUser->execute();

            $db->commit();

            // Generate new JWT
            include_once '../../utils/jwt.php';
            $userQuery = "SELECT * FROM users WHERE user_id = :uid";
            $uStmt = $db->prepare($userQuery);
            $uStmt->bindParam(":uid", $user_id);
            $uStmt->execute();
            $uRow = $uStmt->fetch(PDO::FETCH_ASSOC);

            $token_payload = array(
                "iss" => "queueease.com",
                "iat" => time(),
                "exp" => time() + (60 * 60 * 24 * 7),
                "data" => array(
                    "user_id" => $uRow['user_id'],
                    "name" => $uRow['name'],
                    "email" => $uRow['email'],
                    "role" => $uRow['role']
                )
            );
            $jwt = JWT::encode($token_payload);

            http_response_code(201);
            echo json_encode(array(
                "message" => "Organization created successfully.",
                "org_id" => $org_id,
                "logo_url" => $logo_url,
                "jwt" => $jwt,
                "user" => $token_payload['data']
            ));
        } else {
            $db->rollBack();
            http_response_code(503);
            echo json_encode(array("message" => "Unable to create organization."));
        }
    } catch (Exception $e) {
        if ($db->inTransaction()) {
            $db->rollBack();
        }
        http_response_code(500);
        echo json_encode(array("message" => "Database error: " . $e->getMessage()));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete data. Name, category, and user_id are required."));
}
?>
