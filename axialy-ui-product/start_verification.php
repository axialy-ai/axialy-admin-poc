<?php
// /app.axialy.ai/start_verification.php
require_once 'includes/db_connection.php';
require_once 'includes/account_creation.php';

header('Content-Type: application/json');

$email = $_POST['email'] ?? '';
$accountCreation = new AccountCreation($pdo);

try {
    if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new Exception('Please provide a valid email address.');
    }

    if ($accountCreation->checkEmailExists($email)) {
        throw new Exception('This email address is already registered.');
    }

    $token = $accountCreation->createVerificationToken($email);
    
    if ($accountCreation->sendVerificationEmail($email, $token)) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Verification email sent. Please check your inbox.'
        ]);
    } else {
        throw new Exception('Failed to send verification email. Please try again.');
    }
    
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?>