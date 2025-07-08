<?php
/**
 * Axialy Admin – central DB connection / config helper
 *
 * Public usage (unchanged):
 *   $db = AdminDBConfig::getInstance()->getPdo();  // PDO handle
 *   $host = AdminDBConfig::getInstance()->getHost(); // etc.
 *
 * © 2025 Axialy – All rights reserved.
 */

namespace Axialy\AdminConfig;

use PDO;
use RuntimeException;

final class AdminDBConfig
{
    private const REQUIRED_VARS = ['DB_HOST', 'DB_USER', 'DB_PASSWORD'];

    private static ?self $instance = null;

    /* Connection details */
    private string $host;
    private string $user;
    private string $password;
    private string $port;
    private string $nameAdmin;
    private string $nameUI;

    /** @var PDO[] Lazy-initialised PDO handles, keyed by DB name */
    private array $pdoPool = [];

    /* --------------------------------------------------------------------- */

    /**
     * Singleton accessor.
     */
    public static function getInstance(): self
    {
        return self::$instance ??= new self();
    }

    /**
     * @throws RuntimeException if required env vars are still missing.
     */
    private function __construct()
    {
        // 1️⃣  Load .env once if env vars are missing.
        $this->bootstrapEnvIfRequired();

        // 2️⃣  Validate.
        foreach (self::REQUIRED_VARS as $key) {
            if (getenv($key) === false) {
                throw new RuntimeException(
                    'Missing DB environment variables (DB_HOST / DB_USER / DB_PASSWORD).'
                );
            }
        }

        // 3️⃣  Capture.
        $this->host       = getenv('DB_HOST');
        $this->user       = getenv('DB_USER');
        $this->password   = getenv('DB_PASSWORD');
        $this->port       = getenv('DB_PORT') ?: '3306';
        $this->nameAdmin  = getenv('DB_NAME')     ?: 'axialy_admin';
        $this->nameUI     = getenv('UI_DB_NAME')  ?: 'axialy_ui';
    }

    /* --------------------------------------------------------------------- */
    /*  Public getters                                                       */
    /* --------------------------------------------------------------------- */

    public function getHost(): string      { return $this->host; }
    public function getUser(): string      { return $this->user; }
    public function getPassword(): string  { return $this->password; }
    public function getPort(): string      { return $this->port; }

    /**
     * Convenience: obtain a PDO for the Admin DB (default).
     */
    public function getPdo(): PDO
    {
        return $this->getPdoFor($this->nameAdmin);
    }

    /**
     * Convenience: obtain a PDO for the UI DB.
     */
    public function getPdoUI(): PDO
    {
        return $this->getPdoFor($this->nameUI);
    }

    /**
     * Generic: obtain (and reuse) a PDO for any DB name.
     */
    public function getPdoFor(string $dbName): PDO
    {
        if (!isset($this->pdoPool[$dbName])) {
            $dsn = sprintf(
                'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
                $this->host,
                $this->port,
                $dbName
            );

            $this->pdoPool[$dbName] = new PDO(
                $dsn,
                $this->user,
                $this->password,
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_PERSISTENT         => false,
                ]
            );
        }
        return $this->pdoPool[$dbName];
    }

    /* --------------------------------------------------------------------- */
    /*  Internal helpers                                                     */
    /* --------------------------------------------------------------------- */

    /**
     * If any required env var is absent, attempt to parse a `.env` file in the
     * project root and populate the process environment *once*.
     */
    private function bootstrapEnvIfRequired(): void
    {
        foreach (self::REQUIRED_VARS as $key) {
            if (getenv($key) !== false) {
                continue; // already present
            }

            // Parse .env (key=value, no quotes) – tolerant of Windows line-endings.
            $envPath = dirname(__DIR__, 1) . '/.env';
            if (!is_file($envPath)) {
                return; // Nothing to load.
            }

            $lines = file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            foreach ($lines as $line) {
                if ($line[0] === '#') { continue; }
                [$k, $v] = array_map('trim', explode('=', $line, 2));
                if ($k !== '' && getenv($k) === false) {
                    putenv("$k=$v");
                    $_ENV[$k] = $v; // For frameworks relying on $_ENV
                }
            }
            return; // Loaded once; break out.
        }
    }
}
