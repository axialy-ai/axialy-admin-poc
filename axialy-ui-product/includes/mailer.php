<?php
/**
 * Generic sendMail() helper powered by PHPMailer + Microsoft 365 SMTP.
 * Usage:  sendMail($to, $subject, $html, $textAlt='', $debug=false);
 */
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require_once __DIR__ . '/../vendor/autoload.php';
$config = \AxiaBA\Config\Config::getInstance();

/**
 * @return bool true on success, false on failure (errors logged)
 */
function sendMail(
    string  $to,
    string  $subject,
    string  $htmlBody,
    string  $textAlt = '',
    bool    $debug   = false
): bool {
    global $config;

    $mail = new PHPMailer(true);

    try {
        /* SMTP server */
        $mail->isSMTP();
        $mail->Host       = $config->get('smtp_host')   ?: 'smtp.office365.com';
        $mail->Port       = intval($config->get('smtp_port') ?: 587);
        $mail->SMTPAuth   = true;
        $mail->Username   = $config->get('smtp_user');
        $mail->Password   = $config->get('smtp_password');
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;

        /* optional verbose debug */
        if ($debug) {
            $mail->SMTPDebug  = 2;            // logs commands & replies
            $mail->Debugoutput = static function ($str) {
                error_log('[SMTP-DEBUG] ' . trim($str));
            };
        }

        /* sender & recipient */
        $fromAddr = $config->get('smtp_from_address') ?: 'support@axiaba.com';
        $fromName = $config->get('smtp_from_name')    ?: 'AxiaBA Support';
        $mail->setFrom($fromAddr, $fromName);
        $mail->addAddress($to);

        /* content */
        $mail->isHTML(true);
        $mail->Subject = $subject;
        $mail->Body    = $htmlBody;
        $mail->AltBody = $textAlt !== '' ? $textAlt : strip_tags($htmlBody);

        return $mail->send();
    } catch (Exception $e) {
        error_log('[Mailer] sendMail failed: ' . $e->getMessage());
        return false;
    }
}
