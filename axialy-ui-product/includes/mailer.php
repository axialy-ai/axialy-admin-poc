<?php
/**
 * Centralised mail helper for AxiaBA UI
 *
 *   sendMail(
 *       string  $to,          // recipient
 *       string  $subject,
 *       string  $htmlBody,
 *       string  $altBody = '',// optional plain-text
 *       bool    $debug   = false
 *   ): bool
 *
 * The function prefers PHPMailer (for modern SMTP auth + TLS) but
 * automatically falls back to PHP’s built-in mail() if the library
 * is unavailable.  This prevents fatal “Class … not found” errors.
 */

declare(strict_types=1);

use AxiaBA\Config\Config;

/*-------------------------------------------------
 | 1.  Autoload (if vendor/ exists)
 *------------------------------------------------*/
$autoload = dirname(__DIR__) . '/vendor/autoload.php';
if (is_readable($autoload)) {
    /** @noinspection PhpIncludeInspection */
    require_once $autoload;
}

/*-------------------------------------------------
 | 2.  sendMail() definition
 *------------------------------------------------*/
if (!function_exists('sendMail')) {
    /**
     * @param string $to
     * @param string $subject
     * @param string $htmlBody
     * @param string $altBody
     * @param bool   $debug
     * @return bool  true on success
     */
    function sendMail(
        string $to,
        string $subject,
        string $htmlBody,
        string $altBody = '',
        bool   $debug   = false
    ): bool {
        $cfg = Config::getInstance();
        $fromAddr = $cfg->get('smtp_from_address') ?: 'support@axiaba.com';
        $fromName = $cfg->get('smtp_from_name')   ?: 'AxiaBA';

        /*-----------------------------------------
         | 2a.  Use PHPMailer if available
         *----------------------------------------*/
        if (class_exists('\PHPMailer\PHPMailer\PHPMailer')) {
            try {
                $mail = new \PHPMailer\PHPMailer\PHPMailer(true);

                // debug output
                $mail->SMTPDebug = $debug ? 2 : 0;
                $mail->Debugoutput = function ($str, $level) {
                    error_log("[SMTP-debug:$level] $str");
                };

                $mail->isSMTP();
                $mail->Host       = $cfg->get('smtp_host') ?: 'localhost';
                $mail->Port       = (int)($cfg->get('smtp_port') ?: 25);

                // TLS / SMTPS heuristics
                if (in_array($mail->Port, [465, 587, 2525], true)) {
                    $mail->SMTPSecure = ($mail->Port === 465)
                        ? \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_SMTPS
                        : \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
                }

                $mail->SMTPAuth   = (bool)$cfg->get('smtp_user');
                if ($mail->SMTPAuth) {
                    $mail->Username = $cfg->get('smtp_user');
                    $mail->Password = $cfg->get('smtp_password');
                }

                $mail->CharSet    = 'UTF-8';
                $mail->setFrom($fromAddr, $fromName);
                $mail->addAddress($to);

                $mail->isHTML(true);
                $mail->Subject = $subject;
                $mail->Body    = $htmlBody;
                $mail->AltBody = $altBody ?: strip_tags($htmlBody);

                return $mail->send();
            } catch (\Throwable $e) {
                error_log('[AxiaBA] PHPMailer sendMail error: ' . $e->getMessage());
                return false;
            }
        }

        /*-----------------------------------------
         | 2b.  Fallback to PHP's mail()
         *----------------------------------------*/
        $headers = [
            'MIME-Version: 1.0',
            'Content-type: text/html; charset=UTF-8',
            "From: $fromName <$fromAddr>"
        ];
        $ok = mail($to, $subject, $htmlBody, implode("\r\n", $headers));

        if (!$ok) {
            error_log('[AxiaBA] mail() fallback failed for ' . $to);
        }
        return $ok;
    }
}
