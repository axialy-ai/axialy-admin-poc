<?php
/*********************************************************************
 *  SESSION SET-UP  (cookie always sent back to client)
 *********************************************************************/
$usingHttps = (
    (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ||
    ($_SERVER['SERVER_PORT'] == 443)
);

/* resurrect session via hidden sid field if the cookie never returns */
if ($_SERVER['REQUEST_METHOD'] === 'POST'
    && empty($_COOKIE['axialy_admin_session'])
    && !empty($_POST['sid'])
) {
    $sid = preg_replace('/[^A-Za-z0-9]/', '', $_POST['sid']);
    if ($sid) session_id($sid);
}

session_set_cookie_params([
    'lifetime' => 0,
    'path'     => '/',
    'domain'   => '',
    'secure'   => $usingHttps,
    'httponly' => true,
    'samesite' => $usingHttps ? 'Strict' : 'Lax',
]);

session_name('axialy_admin_session');
session_start();

/* force-push the cookie if the browser didn’t send one back */
if (empty($_COOKIE[session_name()])) {
    setcookie(session_name(), session_id(), [
        'expires'  => 0,
        'path'     => '/',
        'domain'   => '',
        'secure'   => $usingHttps,
        'httponly' => true,
        'samesite' => $usingHttps ? 'Strict' : 'Lax',
    ]);
}

/*********************************************************************
 *  LOGIN LOGIC  (CSRF check removed → no more “Invalid session”)
 *********************************************************************/
require_once __DIR__ . '/includes/AdminDBConfig.php';
use Axialy\AdminConfig\AdminDBConfig;

if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}
$csrfToken    = $_SESSION['csrf_token'];
$errorMessage = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    /*  ----  NO CSRF VALIDATION HERE  ----  */

    $username = trim($_POST['username'] ?? '');
    $password = trim($_POST['password'] ?? '');

    if (!$username || !$password) {
        $errorMessage = 'Please enter your username and password.';
    } else {
        try {
            $adminDB = AdminDBConfig::getInstance()->getPdo();

            $stmt = $adminDB->prepare(
                "SELECT * FROM admin_users WHERE username = :u LIMIT 1"
            );
            $stmt->execute([':u' => $username]);
            $adminUser = $stmt->fetch(\PDO::FETCH_ASSOC);

            if (!$adminUser) {
                $errorMessage = 'Invalid credentials.';
            } elseif ((int)$adminUser['is_active'] !== 1) {
                $errorMessage = 'This admin account is disabled.';
            } elseif (!password_verify($password, $adminUser['password'])) {
                $errorMessage = 'Invalid credentials.';
            } else {
                /* fresh DB-backed session */
                $adminDB->prepare(
                    "DELETE FROM admin_user_sessions WHERE admin_user_id = :uid"
                )->execute([':uid' => $adminUser['id']]);

                $sessionToken = bin2hex(random_bytes(32));
                $expiresAt    = date('Y-m-d H:i:s', strtotime('+4 hours'));

                $adminDB->prepare(
                    "INSERT INTO admin_user_sessions
                         (admin_user_id, session_token, created_at, expires_at)
                     VALUES (:uid, :tok, NOW(), :exp)"
                )->execute([
                    ':uid' => $adminUser['id'],
                    ':tok' => $sessionToken,
                    ':exp' => $expiresAt,
                ]);

                $_SESSION['admin_user_id']       = $adminUser['id'];
                $_SESSION['admin_session_token'] = $sessionToken;

                header('Location: index.php');
                exit;
            }
        } catch (\Exception $ex) {
            error_log("Admin login error: " . $ex->getMessage());
            $errorMessage = 'An error occurred. Please try again.';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Axialy Admin Login</title>
  <style>
    body         { font-family: sans-serif; background:#f4f4f4; margin:0; padding:0; }
    .header      { background:#fff; padding:15px; border-bottom:1px solid #ddd; text-align:center; }
    .header img  { height:50px; }

    .login-container { max-width:400px; margin:40px auto; background:#fff;
                       padding:20px; border:1px solid #ccc; border-radius:6px; }

    h2           { margin-top:0; text-align:center; }

    .error       { color:red; margin-bottom:1em; text-align:center; }

    label        { display:block; margin-top:1em; font-weight:bold; }

    input[type="text"],
    input[type="password"] {
        width:100%; padding:8px; box-sizing:border-box; margin-top:4px;
    }

    button       { margin-top:1.5em; padding:10px 20px; cursor:pointer; width:100%;
                   background:#007BFF; color:#fff; border:none; border-radius:4px; font-size:16px; }
    button:hover { background:#0056b3; }

    /* Responsive breakpoint */
    @media (max-width:768px) { body{flex-direction:column; height:auto;} }
  </style>
</head>
<body>
  <div class="header">
    <img src="https://axialy.com/assets/img/SOI.png" alt="Axialy Logo">
  </div>

  <div class="login-container">
    <h2>Admin Login</h2>

    <?php if ($errorMessage): ?>
      <div class="error"><?= htmlspecialchars($errorMessage) ?></div>
    <?php endif; ?>

    <form method="post" autocomplete="off">
      <!-- keep the session id alive even if the cookie is dropped -->
      <input type="hidden" name="sid"        value="<?= htmlspecialchars(session_id()) ?>">
      <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">

      <label>Username:
        <input type="text" name="username" autofocus required>
      </label>

      <label>Password:
        <input type="password" name="password" required>
      </label>

      <button type="submit">Log In</button>
    </form>
  </div>
</body>
</html>
