<?php
// /includes/db_connection.php

// Load configuration
require_once '/home/i17z4s936h3j/private_axiaba/includes/Config.php';
use AxiaBA\Config\Config;
$config = Config::getInstance();

try {
    // Database credentials from config
    $dbHost = $config['db_host'];
    $dbName = $config['db_name'];
    $dbUser = $config['db_user'];
    $dbPass = $config['db_password'];

    // Create PDO connection
    $dsn = "mysql:host=$dbHost;dbname=$dbName;charset=utf8mb4";
    $pdo = new PDO($dsn, $dbUser, $dbPass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Create mysqli connection for legacy code that requires it
    $conn = new mysqli($dbHost, $dbUser, $dbPass, $dbName);
    
    if ($conn->connect_error) {
        throw new Exception("MySQLi Connection failed: " . $conn->connect_error);
    }

} catch (Exception $e) {
    error_log('Database connection failed: ' . $e->getMessage());
    // Don't expose error details to end users
    die('A database error occurred. Please try again later.');
}
?>
