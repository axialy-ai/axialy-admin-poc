<?php
header('Content-Type: application/json');

// Check request method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

require_once __DIR__ . '/includes/AdminDBConfig.php';
use Axialy\AdminConfig\AdminDBConfig;

try {
    $adminDB = AdminDBConfig::getInstance()->getPdo();

    // Check if 'caseylide' user is already in admin_users
    $stmt = $adminDB->prepare("SELECT COUNT(*) FROM admin_users WHERE username = 'caseylide'");
    $stmt->execute();
    $count = (int)$stmt->fetchColumn();

    if ($count > 0) {
        // Already exists
        echo json_encode(['success' => false, 'message' => 'User "caseylide" already exists.']);
        exit;
    }

    // Insert the user with password 'Casellio'
    $hashed = password_hash('Casellio', PASSWORD_BCRYPT);

    // Debug: Log the hash being created
    error_log("Creating user caseylide with hash: " . $hashed);

    $ins = $adminDB->prepare("
        INSERT INTO admin_users (username, password, email, is_active, is_sys_admin, created_at)
        VALUES ('caseylide', :pass, 'caseylide@gmail.com', 1, 1, NOW())
    ");
    $ins->execute([':pass' => $hashed]);

    // Verify the user was created
    $verify = $adminDB->prepare("SELECT id, username, password, is_active, is_sys_admin FROM admin_users WHERE username = 'caseylide'");
    $verify->execute();
    $newUser = $verify->fetch(\PDO::FETCH_ASSOC);
    
    if ($newUser) {
        error_log("User created successfully: " . json_encode($newUser));
        echo json_encode(['success' => true, 'debug' => 'User created with ID: ' . $newUser['id']]);
    } else {
        echo json_encode(['success' => false, 'message' => 'User creation verification failed']);
    }

} catch (\Exception $ex) {
    error_log("Init user error: " . $ex->getMessage());
    echo json_encode(['success' => false, 'message' => $ex->getMessage()]);
}
