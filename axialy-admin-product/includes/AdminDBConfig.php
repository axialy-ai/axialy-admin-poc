<?php
/**
 * Axialy Admin – central DB connection / config helper
 *
 * Singleton pattern keeps one PDO pool per request.
 *
 * New in this revision (2025‑07‑07):
 *  • Automatically loads .env if required (same as v2).
 *  • **Self‑migrates**: the first time a connection to the Admin DB is
 *    requested, it checks for the core tables (currently just `admin_users`).
 *    If they don’t exist it creates them and seeds the default admin user
 *    from ADMIN_DEFAULT_* env vars. This removes the manual SQL‑import step
 *    that was breaking fresh droplets.
 *
 * Public API remains unchanged.
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

    /* ------------------------------------------------------------------ */
    /**
     * Singleton accessor.
     */
    public static function getInstance(): self
    {
        return self::$instance ??= new self();
    }

    /**
     * @throws RuntimeException if required env vars are missing.
     */
    private function __construct()
    {
        $this->bootstrapEnvIfRequired();

        foreach (self::REQUIRED_VARS as $key) {
            if (getenv($key) === false) {
                throw new RuntimeException(
                    'Missing DB environment variables (DB_HOST / DB_USER / DB_PASSWORD).'
                );
            }
        }

        $this->host       = getenv('DB_HOST');
        $this->user       = getenv('DB_USER');
        $this->password   = getenv('DB_PASSWORD');
        $this->port       = getenv('DB_PORT') ?: '3306';
        $this->nameAdmin  = getenv('DB_NAME')     ?: 'axialy_admin';
        $this->nameUI     = getenv('UI_DB_NAME')  ?: 'axialy_ui';
    }

    /* ------------------------------------------------------------------ */
    /*  Public helpers                                                     */
    /* ------------------------------------------------------------------ */

    public function getPdo(): PDO
    {
        return $this->getPdoFor($this->nameAdmin);
    }

    public function getPdoUI(): PDO
    {
        return $this->getPdoFor($this->nameUI);
    }

    public function getPdoFor(string $dbName): PDO
    {
        if (!isset($this->pdoPool[$dbName])) {
            $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
                $this->host, $this->port, $dbName);

            $pdo = new PDO($dsn, $this->user, $this->password, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_PERSISTENT         => false,
            ]);

            // One‑time migration for the admin DB only.
            if ($dbName === $this->nameAdmin) {
                $this->ensureSchema($pdo);
            }

            $this->pdoPool[$dbName] = $pdo;
        }
        return $this->pdoPool[$dbName];
    }

    /* ------------------------------------------------------------------ */
    /*  Schema bootstrap                                                   */
    /* ------------------------------------------------------------------ */

    /**
     * Creates the minimal schema the admin UI needs on a brand‑new database.
     * Safe to call repeatedly – uses IF NOT EXISTS & UPSERTs.
     */
    private function ensureSchema(PDO $pdo): void
    {
        // 1️⃣  admin_users table
        $pdo->exec("CREATE TABLE IF NOT EXISTS admin_users (
            id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            username    VARCHAR(100) NOT NULL UNIQUE,
            password    VARCHAR(255) NOT NULL,
            email       VARCHAR(255) NULL,
            is_active   TINYINT(1) NOT NULL DEFAULT 1,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

        // 2️⃣  Seed default admin user (idempotent)
        $defUser  = getenv('ADMIN_DEFAULT_USER')     ?: 'admin';
        $defEmail = getenv('ADMIN_DEFAULT_EMAIL')    ?: 'admin@example.com';
        $defPass  = getenv('ADMIN_DEFAULT_PASSWORD') ?: 'ChangeMe123!';
        $hash     = password_hash($defPass, PASSWORD_DEFAULT);

        $stmt = $pdo->prepare("REPLACE INTO admin_users (id, username, password, email, is_active)
                               VALUES (
                                 (SELECT id FROM (SELECT id FROM admin_users WHERE username = :u LIMIT 1) AS x),
                                 :u, :p, :e, 1
                               )");
        $stmt->execute([':u' => $defUser, ':p' => $hash, ':e' => $defEmail]);
    }

    /* ------------------------------------------------------------------ */
    /*  Private helpers                                                    */
    /* ------------------------------------------------------------------ */

    private function bootstrapEnvIfRequired(): void
    {
        foreach (self::REQUIRED_VARS as $key) {
            if (getenv($key) !== false) {
                continue; // already present
            }

            $envPath = dirname(__DIR__, 1) . '/.env';
            if (!is_file($envPath)) {
                return; // nothing to load
            }
            foreach (file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
                if ($line[0] === '#') continue;
                [$k, $v] = array_map('trim', explode('=', $line, 2));
                if ($k !== '' && getenv($k) === false) {
                    putenv("$k=$v");
                    $_ENV[$k] = $v;
                }
            }
            return; // loaded once
        }
    }
}
