<?php
/**
 * Generic account-creation helper for AxiaBA
 */
declare(strict_types=1);

require_once __DIR__ . '/db_connection.php';   // gives $pdo
require_once __DIR__ . '/../vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

class AccountCreation
{
    private PDO $pdo;

    public function __construct(PDO $pdo)
    {
        $this->pdo = $pdo;
    }

    /* --------------------------------------------------
     *  Basic look-ups / helpers
     * ------------------------------------------------ */
    public function checkEmailExists(string $email): bool
    {
        $stmt = $this->pdo->prepare(
            'SELECT 1 FROM users WHERE email = ? LIMIT 1'
        );
        $stmt->execute([$email]);
        return (bool) $stmt->fetchColumn();
    }

    public function createVerificationToken(string $email): string
    {
        $token = bin2hex(random_bytes(32));

        $stmt = $this->pdo->prepare(
            'INSERT INTO email_verifications (email, token, created_at)
             VALUES (?, ?, NOW())'
        );
        $stmt->execute([$email, $token]);

        return $token;
    }

    /* --------------------------------------------------
     *  SEND THE BLOODY E-MAIL
     * ------------------------------------------------ */
    public function sendVerificationEmail(
        string $email,
        string $token,
        bool   $debug = false
    ): bool {
        $mail = new PHPMailer(true);

        try {
            /* SMTP ---------------------------------------------------------------- */
            $mail->isSMTP();
            $mail->Host       = getenv('SMTP_HOST') ?: 'smtp.sendgrid.net';
            $mail->Port       = (int) (getenv('SMTP_PORT') ?: 2525);
            $mail->SMTPAuth   = true;
            $mail->Username   = getenv('SMTP_USER') ?: 'apikey';
            $mail->Password   = getenv('SMTP_PASSWORD') ?: '';
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;

            if ($debug) {
                // 2 dumps full SMTP convo to error_log
                $mail->SMTPDebug = 2;
            }

            /* Headers & body ------------------------------------------------------ */
            $mail->setFrom('no-reply@axiaba.com', 'AxiaBA');
            $mail->addAddress($email);

            $mail->Subject = 'Verify your AxiaBA account';

            $baseURL  = rtrim(
                getenv('APP_BASE_URL') ?: 'https://app.axialy.ai',
                '/'
            );
            $verifyURL = $baseURL . '/verify_email.php?token=' . $token;

            $mail->Body = <<<BODY
Hi,

Thanks for signing up for AxiaBA!

Just click the link below to verify your e-mail address and finish creating
your account:

$verifyURL

If you didn’t request this, you can safely ignore this message.

— The AxiaBA Team
BODY;

            return $mail->send();
        } catch (Exception $e) {
            error_log('[AxiaBA] PHPMailer error: ' . $mail->ErrorInfo);
            return false;
        }
    }

    /* --------------------------------------------------
     *  Token verification
     * ------------------------------------------------ */
    public function verifyToken(string $token): ?string
    {
        $stmt = $this->pdo->prepare(
            'SELECT email FROM email_verifications
             WHERE token = ?
               AND used  = 0
               AND created_at >= (NOW() - INTERVAL 24 HOUR)'
        );
        $stmt->execute([$token]);
        $email = $stmt->fetchColumn();

        if ($email) {
            $stmt = $this->pdo->prepare(
                'UPDATE email_verifications SET used = 1 WHERE token = ?'
            );
            $stmt->execute([$token]);
            return $email;
        }
        return null;
    }

    /* --------------------------------------------------
     *  Final account creation
     * ------------------------------------------------ */
    public function createAccount(
        string $email,
        string $username,
        string $password
    ): bool {
        $hash = password_hash($password, PASSWORD_DEFAULT);

        $this->pdo->beginTransaction();
        try {
            $stmt = $this->pdo->prepare(
                'INSERT INTO users
                 (email, username, password_hash, created_at)
                 VALUES (?, ?, ?, NOW())'
            );
            $stmt->execute([$email, $username, $hash]);

            // …any other one-time setup here…

            $this->pdo->commit();
            return true;
        } catch (Throwable $e) {
            $this->pdo->rollBack();
            error_log('[AxiaBA] createAccount error: ' . $e->getMessage());
            return false;
        }
    }
}
