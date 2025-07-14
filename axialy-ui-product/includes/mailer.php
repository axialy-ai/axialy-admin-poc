<?php
/**
 * Central mail helper for AxiaBA-UI
 *
 *   sendMail(
 *       string  $to,
 *       string  $subject,
 *       string  $htmlBody,
 *       string  $altBody = '',
 *       bool    $debug   = false
 *   ): bool
 *
 * 2025-07-14 – Improvements
 *   • Supports explicit SMTP_SECURE (ssl | tls | none).
 *   • Logs PHPMailer::ErrorInfo when send() returns false.
 */

declare(strict_types=1);
use AxiaBA\Config\Config;

/* 0) Autoload composer dependencies if present */
$autoload = dirname(__DIR__) . '/vendor/autoload.php';
if (is_readable($autoload)) {
    /** @noinspection PhpIncludeInspection */
    require_once $autoload;
}

/* 1) Define helper only once */
if (!function_exists('sendMail')) {

    /**
     * Sends a single e-mail message. Returns true on first successful transport.
     */
    function sendMail(
        string $to,
        string $subject,
        string $htmlBody,
        string $altBody = '',
        bool   $debug   = false
    ): bool {

        $cfg      = Config::getInstance();
        $fromAddr = $cfg->get('smtp_from_address') ?: 'support@axiaba.com';
        $fromName = $cfg->get('smtp_from_name')   ?: 'AxiaBA';

        /* A) Preferred transport: PHPMailer via authenticated SMTP */
        if (class_exists('\PHPMailer\PHPMailer\PHPMailer')) {
            try {
                $mail = new \PHPMailer\PHPMailer\PHPMailer(true);

                // optional verbose output
                $mail->SMTPDebug   = $debug ? 2 : 0;
                $mail->Debugoutput = static function ($str, $level) {
                    error_log("[SMTP-debug:$level] $str");
                };

                $mail->isSMTP();
                $mail->Host = $cfg->get('smtp_host') ?: 'localhost';
                $mail->Port = (int)($cfg->get('smtp_port') ?: 25);

                /* encryption:
                 *  – honour SMTP_SECURE if provided,
                 *  – otherwise fall back to port heuristic.
                 */
                $securePref = strtolower($cfg->get('smtp_secure') ?? '');
                if ($securePref !== '') {
                    $mail->SMTPSecure = match ($securePref) {
                        'ssl', 'smtps'   => \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_SMTPS,
                        'tls', 'starttls'=> \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS,
                        'none'           => false,
                        default          => $mail->SMTPSecure,
                    };
                } else {
                    // heuristic: 465 → SMTPS, 587/2525 → STARTTLS
                    if ($mail->Port === 465) {
                        $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_SMTPS;
                    } elseif (in_array($mail->Port, [587, 2525], true)) {
                        $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
                    }
                }

                $mail->SMTPAuth = (bool)$cfg->get('smtp_user');
                if ($mail->SMTPAuth) {
                    $mail->Username = $cfg->get('smtp_user');
                    $mail->Password = $cfg->get('smtp_password');
                }

                $mail->CharSet  = 'UTF-8';
                $mail->setFrom($fromAddr, $fromName);
                $mail->addAddress($to);

                $mail->isHTML(true);
                $mail->Subject = $subject;
                $mail->Body    = $htmlBody;
                $mail->AltBody = $altBody ?: strip_tags($htmlBody);

                if ($mail->send()) {
                    return true; // ✅ sent via PHPMailer
                }

                // send() returned FALSE – record the reason
                error_log('[AxiaBA] PHPMailer send() failed: ' . $mail->ErrorInfo
                          . ' – falling back to mail()');
            } catch (\Throwable $e) {
                error_log('[AxiaBA] PHPMailer exception: ' . $e->getMessage()
                          . ' – falling back to mail()');
            }
        }

        /* B) Fallback transport: PHP’s mail() */
        $headers = [
            'MIME-Version: 1.0',
            'Content-type: text/html; charset=UTF-8',
            "From: $fromName <$fromAddr>",
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
