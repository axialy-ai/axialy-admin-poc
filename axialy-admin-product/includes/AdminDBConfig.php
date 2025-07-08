<?php
/**
 * Axialy Admin – central DB connection / config helper (v3-hotfix-is_sys_admin – 2025-07-07)
 *
 *  • Guarantees **is_sys_admin** exists in admin_users (fresh create + in-place ALTER).
 *  • Creates the two admin_* tables automatically on an empty database.
 *  • Does **NOT** seed any rows – bootstrap flow (index.php → init_user.php) stays unchanged.
 *
 *  Public API:
 *     AdminDBConfig::getInstance() → singleton
 *     ->getPdo()                   → PDO to axialy_admin
 *     ->getPdoUI()                 → PDO to axialy_ui
 *     ->getPdoFor($dbName)         → PDO to any DB name
 */

namespace Axialy\AdminConfig;

use PDO;
use RuntimeException;

final class AdminDBConfig
{
    private const REQUIRED_VARS = ['DB_HOST', 'DB_USER', 'DB_PASSWORD'];

    private static ?self $instance = null;

    private string $host;
    private string $user;
    private string $password;
    private string $port;
    private string $nameAdmin;
    private string $nameUI;

    /** @var PDO[] */
    private array $pdoPool = [];

    /*──────────────────────────────────────────────────────────────*/
    public static function getInstance(): self
    {
        return self::$instance ??= new self();
    }

    private function __construct()
    {
        $this->bootstrapEnvIfNeeded();

        foreach (self::REQUIRED_VARS as $key) {
            if (getenv($key) === false) {
                throw new RuntimeException('Missing DB environment variables (DB_HOST / DB_USER / DB_PASSWORD).');
            }
        }

        $this->host      = getenv('DB_HOST');
        $this->user      = getenv('DB_USER');
        $this->password  = getenv('DB_PASSWORD');
        $this->port      = getenv('DB_PORT') ?: '3306';
        $this->nameAdmin = getenv('DB_NAME')    ?: 'axialy_admin';
        $this->nameUI    = getenv('UI_DB_NAME') ?: 'axialy_ui';
    }

    /*─────────────── public helpers ───────────────*/
    public function getPdo()   : PDO { return $this->getPdoFor($this->nameAdmin); }
    public function getPdoUI() : PDO { return $this->getPdoFor($this->nameUI);   }

    public function getPdoFor(string $dbName): PDO
    {
        if (!isset($this->pdoPool[$dbName])) {
            $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $this->host, $this->port, $dbName);

            $pdo = new PDO(
                $dsn,
                $this->user,
                $this->password,
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_PERSISTENT         => false,
                ]
            );

            if ($dbName === $this->nameAdmin) {
                $this->ensureSchema($pdo);
            }
            $this->pdoPool[$dbName] = $pdo;
        }
        return $this->pdoPool[$dbName];
    }

    /*────────────── internal helpers ──────────────*/
    /**
     * Ensures admin_* tables exist **and** admin_users has is_sys_admin.
     */
    private function ensureSchema(PDO $pdo): void
    {
        // Fresh-install create
        $pdo->exec("CREATE TABLE IF NOT EXISTS admin_users (
            id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            username     VARCHAR(100) NOT NULL UNIQUE,
            password     VARCHAR(255) NOT NULL,
            email        VARCHAR(255) NULL,
            is_active    TINYINT(1) NOT NULL DEFAULT 1,
            is_sys_admin TINYINT(1) NOT NULL DEFAULT 1,
            created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

        $pdo->exec("CREATE TABLE IF NOT EXISTS admin_user_sessions (
            id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            admin_user_id  INT UNSIGNED NOT NULL,
            session_token  CHAR(64) NOT NULL,
            created_at     DATETIME NOT NULL,
            expires_at     DATETIME NOT NULL,
            INDEX(session_token),
            CONSTRAINT fk_admin_sessions_user
              FOREIGN KEY (admin_user_id) REFERENCES admin_users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

        // In-place upgrade (older DB missing is_sys_admin)
        try {
            $pdo->exec("ALTER TABLE admin_users
                          ADD COLUMN IF NOT EXISTS is_sys_admin TINYINT(1) NOT NULL DEFAULT 1
                          AFTER is_active;");
        } catch (\PDOException $e) {
            // MariaDB/MySQL < 8.0.13 don’t understand IF NOT EXISTS – ignore dup-column (1060/1061)
            if (!in_array($e->errorInfo[1] ?? null, [1060, 1061], true)) {
                throw $e;
            }
        }
    }

    /** Loads .env once if any required var is absent. */
    private function bootstrapEnvIfNeeded(): void
    {
        foreach (self::REQUIRED_VARS as $v) {
            if (getenv($v) === false) {
                $env = dirname(__DIR__, 1) . '/.env';
                if (!is_file($env)) return;
                foreach (file($env, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
                    if ($line[0] === '#' || !str_contains($line, '=')) continue;
                    [$k, $val] = array_map('trim', explode('=', $line, 2));
                    if ($k && getenv($k) === false) {
                        putenv("$k=$val");
                        $_ENV[$k] = $val;
                    }
                }
                break;
            }
        }
    }
}
