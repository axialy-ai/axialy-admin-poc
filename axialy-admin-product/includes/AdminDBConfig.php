<?php
/**
 * Axialy Admin – central DB connection / config helper (v3 - 2025-07-07)
 *
 *  • Creates required tables automatically on an empty database so the first
 *    browser hit doesn’t explode with “table not found”.
 *  • **Does NOT pre-seed any rows** – the original bootstrap flow
 *      index.php → init_user.php  still runs.
 */

namespace Axialy\AdminConfig;

use PDO;
use RuntimeException;

final class AdminDBConfig
{
    private const REQUIRED_VARS = ['DB_HOST','DB_USER','DB_PASSWORD'];

    private static ?self $instance = null;

    private string $host;
    private string $user;
    private string $password;
    private string $port;
    private string $nameAdmin;
    private string $nameUI;

    /** @var PDO[] lazy PDO pool  */
    private array $pdoPool = [];

    /* ──────────────────────────────────────────────────────────────── */
    public static function getInstance(): self
    {
        return self::$instance ??= new self();
    }

    private function __construct()
    {
        $this->bootstrapEnvIfNeeded();

        foreach (self::REQUIRED_VARS as $k) {
            if (getenv($k) === false) {
                throw new RuntimeException('Missing DB_* environment variables.');
            }
        }

        $this->host      = getenv('DB_HOST');
        $this->user      = getenv('DB_USER');
        $this->password  = getenv('DB_PASSWORD');
        $this->port      = getenv('DB_PORT') ?: '3306';
        $this->nameAdmin = getenv('DB_NAME')     ?: 'axialy_admin';
        $this->nameUI    = getenv('UI_DB_NAME')  ?: 'axialy_ui';
    }

    /* ───────────────────────── public helpers ────────────────────── */
    public function getPdo()   : PDO { return $this->getPdoFor($this->nameAdmin); }
    public function getPdoUI() : PDO { return $this->getPdoFor($this->nameUI);   }

    public function getPdoFor(string $dbName): PDO
    {
        if (!isset($this->pdoPool[$dbName])) {
            $dsn = sprintf(
                'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
                $this->host, $this->port, $dbName
            );

            $pdo = new PDO(
                $dsn,
                $this->user,
                $this->password,
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]
            );

            if ($dbName === $this->nameAdmin) {
                $this->ensureSchema($pdo);          // ← new
            }
            $this->pdoPool[$dbName] = $pdo;
        }
        return $this->pdoPool[$dbName];
    }

    /* ─────────────────────── internal helpers ────────────────────── */
    /** Creates the two admin_* tables when they aren’t present. */
    private function ensureSchema(PDO $pdo): void
    {
        $pdo->exec("CREATE TABLE IF NOT EXISTS admin_users (
            id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            username    VARCHAR(100) NOT NULL UNIQUE,
            password    VARCHAR(255) NOT NULL,
            email       VARCHAR(255) NULL,
            is_active   TINYINT(1) NOT NULL DEFAULT 1,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

        $pdo->exec("CREATE TABLE IF NOT EXISTS admin_user_sessions (
            id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            admin_user_id INT UNSIGNED NOT NULL,
            session_token CHAR(64) NOT NULL,
            created_at    DATETIME NOT NULL,
            expires_at    DATETIME NOT NULL,
            INDEX(session_token),
            CONSTRAINT fk_admin_sessions_user
                FOREIGN KEY (admin_user_id) REFERENCES admin_users(id)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    }

    /** Loads .env once if any required var is absent. */
    private function bootstrapEnvIfNeeded(): void
    {
        foreach (self::REQUIRED_VARS as $v) {
            if (getenv($v) === false) {
                $env = dirname(__DIR__,1).'/.env';
                if (!is_file($env)) return;
                foreach (file($env, FILE_IGNORE_NEW_LINES|FILE_SKIP_EMPTY_LINES) as $line) {
                    if ($line[0]==='#' || !str_contains($line,'=')) continue;
                    [$k,$val] = array_map('trim', explode('=', $line, 2));
                    if ($k && getenv($k)===false) {
                        putenv("$k=$val");
                        $_ENV[$k] = $val;
                    }
                }
                break;
            }
        }
    }
}
