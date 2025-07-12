<?php
// /includes/db_connection.php
declare(strict_types=1);

require_once __DIR__ . '/Config.php';
use AxiaBA\Config\Config;

/* ------------------------------------------------------------------ */
/* 1) Grab credentials from env (or .env via Config helper)           */
/* ------------------------------------------------------------------ */
$cfg     = Config::getInstance();
$dbHost  = $cfg->get('db_host')     ?? '';
$dbName  = $cfg->get('db_name')     ?? 'Axialy_UI';
$dbUser  = $cfg->get('db_user')     ?? '';
$dbPass  = $cfg->get('db_password') ?? '';
$dbPort  = getenv('UI_DB_PORT') ?: '3306';

/* sanity-check                                                           */
if (!$dbHost || !$dbUser || !$dbPass) {
    throw new RuntimeException(
        'UI DB credentials missing – set UI_DB_* env variables or .env file.'
    );
}

/* ------------------------------------------------------------------ */
/* 2) PDO connection (preferred)                                       */
/* ------------------------------------------------------------------ */
$dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
               $dbHost, $dbPort, $dbName);

try {
    /** @var PDO $pdo */
    $pdo = new PDO(
        $dsn, $dbUser, $dbPass,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );
} catch (Throwable $e) {
    error_log('[PDO] DB connection failed: '.$e->getMessage());
    die('Database connection error.');
}

/* ------------------------------------------------------------------ */
/* 3) Legacy mysqli for a few old queries                              */
/* ------------------------------------------------------------------ */
$mysqliDsn = mysqli_init();
$mysqliDsn->options(MYSQLI_OPT_CONNECT_TIMEOUT, 5);
if (!$mysqliDsn->real_connect($dbHost, $dbUser, $dbPass, $dbName, (int)$dbPort)) {
    error_log('[MySQLi] connect_error: '.$mysqliDsn->connect_error);
    die('Database connection error.');
}
$conn = $mysqliDsn;     // keep original variable name for legacy code
