<?php
require_once 'includes/db_connection.php';
require_once 'includes/mailer.php';                    // NEW mail helper
$config = require '/home/i17z4s936h3j/private_axiaba/includes/Config.php'; // <<<clide>>>

header('Content-Type: application/json');

/* helpers */
function generateToken(int $length = 32): string {
    return bin2hex(random_bytes($length));
}

function sendContentReviewEmail(string $to, string $link): bool {
    $subject = 'Content Review Request';
    $html = "
        <html><body>
        <p>Hello,</p>
        <p>You have been requested to review content in AxiaBA. Click the link below:</p>
        <p><a href='$link'>Review Content</a></p>
        <p>Thank you.</p>
        </body></html>";
    return sendMail($to, $subject, $html, strip_tags($html));
}

/* validate input */
$data = json_decode(file_get_contents('php://input'), true);
if (!isset($data['emails']) || !is_array($data['emails']) || empty($data['emails'])) {
    echo json_encode(['success'=>false,'message'=>'No e-mails provided.']);
    exit;
}
$emails     = array_map('trim', $data['emails']);
$feedback   = isset($data['feedback'])   ? trim($data['feedback'])   : '';
$package_id = isset($data['package_id']) ? intval($data['package_id']) : 0;

if ($package_id <= 0) {
    echo json_encode(['success'=>false,'message'=>'Invalid package ID.']); exit;
}
if (strlen($feedback) > 1000) {
    echo json_encode(['success'=>false,'message'=>'Feedback too long (max 1000 chars).']); exit;
}

/* send mails */
$failed = [];
foreach ($emails as $email) {
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $failed[] = $email; continue;
    }

    $token = generateToken();
    $review_link = rtrim($config['app_base_url'], '/') . "/content_review_form.php?token=$token";

    try {
        $stmt = $pdo->prepare("INSERT INTO content_reviews
            (package_id, email, token, feedback, created_at, completed)
            VALUES (:pid, :email, :token, :feedback, NOW(), 0)");
        $stmt->execute([
            ':pid'      => $package_id,
            ':email'    => $email,
            ':token'    => $token,
            ':feedback' => $feedback
        ]);
    } catch (PDOException $e) {
        error_log('DB insert failed for '.$email.': '.$e->getMessage());
        $failed[] = $email; continue;
    }

    if (!sendContentReviewEmail($email, $review_link)) {
        $failed[] = $email;
    }
}

/* response */
if (empty($failed)) {
    echo json_encode(['success'=>true]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to send to: '.implode(', ', $failed)
    ]);
}
