<?php
/**
 * Axialy – AdminDBConfig
 * --------------------------------------------------------------------------
 *  • Primary source of truth → environment variables (set by Docker/Ansible)
 *    ─ DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
 *  • Optional local fallback: read the first readable “.env” file found
 *    one or two levels above /includes/ (handy for dev without Docker)
 *  • PDO is created lazily and kept as a singleton.
 */

namespace Axialy\AdminConfig;

class AdminDBConfig
{
    private static ?self $instance = null;
    private \PDO $pdo;

    /** Disallow direct construction */
    private function __construct()
    {
        // Make sure required env vars exist (try to bootstrap from .env if not)
        $this->ensureEnvVars();

        $host = getenv('DB_HOST')       ?: '';
        $port = getenv('DB_PORT')       ?: '3306';
        $db   = getenv('DB_NAME')       ?: 'Axialy_ADMIN';
        $user = getenv('DB_USER')       ?: '';
        $pass = getenv('DB_PASSWORD')   ?: '';

        if ($host === '' || $user === '' || $pass === '') {
            throw new \RuntimeException(
                'Missing DB environment variables (DB_HOST / DB_USER / DB_PASSWORD).'
            );
        }

        $dsn = sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
            $host,
            $port,
            $db
        );

        $this->pdo = new \PDO(
            $dsn,
            $user,
            $pass,
            [
                \PDO::ATTR_ERRMODE            => \PDO::ERRMODE_EXCEPTION,
                \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
                \PDO::ATTR_PERSISTENT         => false,
            ]
        );
    }

    /** --------------------------------------------------------------------
     *  Exposed API
     *  ------------------------------------------------------------------ */
    public static function getInstance(): self
    {
        return self::$instance ??= new self();
    }

    public function getPdo(): \PDO
    {
        return $this->pdo;
    }

    /** --------------------------------------------------------------------
     *  Helpers
     *  ------------------------------------------------------------------ */
    private function ensureEnvVars(): void
    {
        if (getenv('DB_HOST') !== false) {
            return;                     // Everything already set (container)
        }

        // Dev mode – try to read a local .env
        $candidates = [
            dirname(__DIR__, 2) . '/.env',     // project root
            dirname(__DIR__, 3) . '/.env',     // one level higher
        ];

        foreach ($candidates as $file) {
            if (!is_readable($file)) {
                continue;
            }

            foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
                $line = trim($line);
                if ($line === '' || $line[0] === '#') {
                    continue;
                }
                if (!str_contains($line, '=')) {
                    continue;
                }

                [$k, $v] = array_map('trim', explode('=', $line, 2));
                // Don’t overwrite existing values
                if ($k !== '' && getenv($k) === false) {
                    putenv("$k=$v");
                }
            }
            // Stop after the first readable .env
            break;
        }
    }

    /** Block cloning & unserialising */
    private function __clone() {}
    public function __wakeup() { throw new \Exception('Cannot unserialise singleton'); }
}
