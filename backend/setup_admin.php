<?php
include_once 'config/database.php';

try {
    // 1. Connect without DB name to create DB if it doesn't exist
    $pdo = new PDO("mysql:host=localhost", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "Creating database if not exists...\n";
    $pdo->exec("CREATE DATABASE IF NOT EXISTS queueease CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $pdo->exec("USE queueease");

    // 2. Import the schema
    echo "Importing schema from db_schema.sql...\n";
    $sql = file_get_contents('db_schema.sql');
    if ($sql) {
        $pdo->exec($sql);
        echo "Schema imported successfully.\n";
    } else {
        echo "Could not read db_schema.sql\n";
    }

    // 3. Insert Admin User
    echo "Inserting Admin User...\n";
    $username = 'Arcenix';
    $password = 'Arx@0808';
    $email = 'admin@queueease.com';
    $hash = password_hash($password, PASSWORD_BCRYPT);

    $stmt = $pdo->prepare("INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, 'SUPER_ADMIN') ON DUPLICATE KEY UPDATE password_hash = ?, role = 'SUPER_ADMIN'");
    $stmt->execute([$username, $email, $hash, $hash]);

    echo "Admin user '$username' created successfully!\n";

} catch(PDOException $e) {
    echo "Database Error: " . $e->getMessage() . "\n";
}
?>
