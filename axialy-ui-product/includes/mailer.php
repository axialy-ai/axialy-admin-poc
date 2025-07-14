<?php
/**
 * Central mail helper for AxiaBA-UI
 *
 *   sendMail(
 *       string  $to,
 *       string  $subject,
 *       string  $htmlBody,
 *       string  $altBody = '',
 *       bool    $debug   = false      // verbose SMTP output to error_log
 *   ): bool
 *
 * 1. Loads Composer’s autoloader if available.
 * 2. Prefers PHPMailer for authenticated TLS SMTP.
 * 3. If PHPMailer is missing *or* the SMTP send fails, falls back to PHP’s
 *    built-in mail() so the application never fatals.
 */

declare(strict_types=1);

use AxiaBA\Config\Config;

/*-------------------------------------------------
 | 0. Autoload (if vendor/ exists)
 *------------------------------------------------*/
$autoload = dirname(__DIR__) . '/vendor/autoload.php';
if (is_readable($autoload)) {
    /** @noinspection PhpIncludeInspection */
    require_once $autoload;
}

/*-------------------------------------------------
 | 1. Function definition
 *------------------------------------------------*/
if (!function_exists('sendMail')) {

    /**
     * @return bool true if *any* transport succeeded
     */
    function sendMail(
        string $to,
        string $subject,
        string $htmlBody,
        string $altBody = '',
        bool   $debug   = false
    ): bool {

        $cfg       = Config::getInstance();
        $fromAddr  = $cfg->get('smtp_from_address') ?: 'support@axiaba.com';
        $fromName  = $cfg->get('smtp_from_name')   ?: 'AxiaBA';

        /*───────────────────────────────────────────────
         | A. Try PHPMailer if the class is available
         *───────────────────────────────────────────────*/
        if (class_exists('\PHPMailer\PHPMailer\PHPMailer')) {
            try {
                $mail = new \PHPMailer\PHPMailer\PHPMailer(true);

                // debugging
                $mail->SMTPDebug  = $debug ? 2 : 0;
                $mail->Debugoutput = function ($str, $level) {
                    error_log("[SMTP-debug:$level] $str");
                };

                $mail->isSMTP();
                $mail->Host       = $cfg->get('smtp_host') ?: 'localhost';
                $mail->Port       = (int)($cfg->get('smtp_port') ?: 25);

                /* encryption heuristics */
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

                if ($mail->send()) {
                    return true;                // ✅ success via PHPMailer
                }
                // If we get here send() returned false (rare) – fall through
                error_log('[AxiaBA] PHPMailer send() returned false, attempting mail() fallback');
            } catch (\Throwable $e) {
                error_log('[AxiaBA] PHPMailer error: ' . $e->getMessage()
                          . ' – attempting mail() fallback');
            }
        }

        /*───────────────────────────────────────────────
         | B. Fallback to PHP’s mail()
         *───────────────────────────────────────────────*/
        $headers = [
            'MIME-Version: 1.0',
            'Content-type: text/html; charset=UTF-8',
            "From: $fromName <$fromAddr>"
        ];
        $ok = mail($to, $subject, $htmlBody, implode("\r\n", $headers));

        if (!$ok) {
            error_log('[AxiaBA] mail() fallback failed for ' . $to);
        } elseif ($debug) {
            error_log('[AxiaBA] mail() fallback succeeded for ' . $to);
        }
        return $ok;
    }
}
