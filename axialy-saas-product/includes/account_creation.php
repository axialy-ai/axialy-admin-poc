<?php
// /app.axiaba.com/includes/account_creation.php

require_once '/home/i17z4s936h3j/private_axiaba/includes/Config.php';
use AxiaBA\Config\Config;

class AccountCreation {
    private $pdo;
    private $config;
    
    public function __construct($pdo) {
        $this->pdo = $pdo;
        global $config;
        $this->config = $config;
    }
    
    public function checkEmailExists($email) {
        $stmt = $this->pdo->prepare('SELECT COUNT(*) FROM ui_users WHERE user_email = ?');
        $stmt->execute([$email]);
        return $stmt->fetchColumn() > 0;
    }
    
    public function createVerificationToken($email) {
        // Generate a secure random token
        $token = bin2hex(random_bytes(32));
        $expires = date('Y-m-d H:i:s', strtotime('+24 hours'));
        
        // Store verification token
        $stmt = $this->pdo->prepare('
            INSERT INTO email_verifications 
            (email, token, expires_at) 
            VALUES (?, ?, ?)
        ');
        $stmt->execute([$email, $token, $expires]);
        
        return $token;
    }
    
    public function sendVerificationEmail($email, $token) {
        // Use the configured app_base_url to build the verification link
        $verificationLink = rtrim($this->config['app_base_url'], '/') . '/verify_email.php?token=' . urlencode($token);
        
        $to = $email;
        $subject = 'Verify your email for AxiaBA';
        
        // Updated message includes the full link below the clickable hyperlink
        $message = "
        <html>
        <head>
            <title>Email Verification</title>
        </head>
        <body>
            <h2>Welcome to AxiaBA</h2>
            <p>Please click the link below to verify your email address:</p>
            <p><a href='$verificationLink'>Verify Email Address</a></p>
            
            <p>If the above link is not clickable or doesn't work, please copy and paste this URL into your browser:</p>
            <p>$verificationLink</p>
            
            <p>This link will expire in 24 hours.</p>
            <p>If you didn't request this verification, please ignore this email.</p>
        </body>
        </html>
        ";
        
        $headers = [
            'MIME-Version: 1.0',
            'Content-type: text/html; charset=UTF-8',
            'From: AxiaBA <support@axiaba.com>',
            'Reply-To: support@axiaba.com'
        ];
        
        return mail($to, $subject, $message, implode("\r\n", $headers));
    }
    
    public function verifyToken($token) {
        $stmt = $this->pdo->prepare('
            SELECT email 
            FROM email_verifications 
            WHERE token = ? 
            AND expires_at > NOW() 
            AND used = 0
        ');
        $stmt->execute([$token]);
        return $stmt->fetchColumn();
    }
    
    public function createAccount($email, $username, $password) {
        try {
            $this->pdo->beginTransaction();
            
            // Create organization
            $stmt = $this->pdo->prepare('
                INSERT INTO default_organizations 
                (default_organization_name) 
                VALUES (?)
            ');
            $stmt->execute([$email]);
            $orgId = $this->pdo->lastInsertId();
            
            // Create user
            $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
            $stmt = $this->pdo->prepare('
                INSERT INTO ui_users 
                (username, password, user_email, default_organization_id) 
                VALUES (?, ?, ?, ?)
            ');
            $stmt->execute([$username, $hashedPassword, $email, $orgId]);
            
            // Mark verification as used
            $stmt = $this->pdo->prepare('
                UPDATE email_verifications 
                SET used = 1 
                WHERE email = ? 
                AND used = 0
            ');
            $stmt->execute([$email]);
            
            $this->pdo->commit();
            
            // Send welcome email after successful creation
            $this->sendWelcomeEmail($email);
            
            return true;
        } catch (\Exception $e) {
            $this->pdo->rollBack();
            error_log("Account creation error: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Sends a simple welcome email after account creation is successful
     */
    private function sendWelcomeEmail($email) {
        $subject = 'Your AxiaBA account is ready!';
        $message = "
        <html>
        <head>
            <title>Welcome to AxiaBA</title>
        </head>
        <body>
            <h2>Welcome aboard!</h2>
            <p>Your account has been created successfully. You can now log in at:</p>
            <p><a href='" . rtrim($this->config['app_base_url'], '/') . "/login.php'>AxiaBA Login</a></p>
            <p>Thank you for choosing AxiaBA!</p>
        </body>
        </html>
        ";
        
        $headers = [
            'MIME-Version: 1.0',
            'Content-type: text/html; charset=UTF-8',
            'From: AxiaBA <support@axiaba.com>',
            'Reply-To: support@axiaba.com'
        ];
        
        @mail($email, $subject, $message, implode("\r\n", $headers));
    }
}
?>
