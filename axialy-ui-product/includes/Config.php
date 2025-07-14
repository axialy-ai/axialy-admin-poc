<?php
/**
 * Lightweight, env-variable-driven configuration helper for Axialy-UI.
 *
 * 2025-07-14  ── CHANGE LOG ────────────────────────────────────────────────
 *  • Always parses the closest .env file and fills any still-null keys.
 *  • Added optional `smtp_secure` mapping (ssl | tls | none).
 *  • No existing public API calls changed – fully backward-compatible.
 */
namespace AxiaBA\Config;

final class Config implements \ArrayAccess
{
    private static ?self $instance = null;      // singleton
    private array $cache = [];                  // logical-key ⇒ value

    /** logical-key ⇒ ENV var */
    private const MAP = [
        // Database (UI)
        'db_host'                => 'UI_DB_HOST',
        'db_name'                => 'UI_DB_NAME',
        'db_user'                => 'UI_DB_USER',
        'db_password'            => 'UI_DB_PASSWORD',

        // Services
        'api_base_url'           => 'API_BASE_URL',
        'app_base_url'           => 'APP_BASE_URL',
        'internal_api_key'       => 'INTERNAL_API_KEY',

        // Stripe
        'stripe_api_key'         => 'STRIPE_API_KEY',
        'stripe_publishable_key' => 'STRIPE_PUBLISHABLE_KEY',
        'stripe_webhook_secret'  => 'STRIPE_WEBHOOK_SECRET',

        // SMTP
        'smtp_host'              => 'SMTP_HOST',
        'smtp_port'              => 'SMTP_PORT',
        'smtp_user'              => 'SMTP_USER',
        'smtp_password'          => 'SMTP_PASSWORD',
        'smtp_from_address'      => 'SMTP_FROM_ADDRESS',
        'smtp_from_name'         => 'SMTP_FROM_NAME',
        'smtp_secure'            => 'SMTP_SECURE',   // NEW

        // Misc
        'app_version'            => 'APP_VERSION',
    ];

    /* ───────── constructor ───────── */
    private function __construct()
    {
        /* 1) read directly from the process environment */
        foreach (self::MAP as $key => $env) {
            $this->cache[$key] = getenv($env) !== false ? getenv($env) : null;
        }

        /* 2) locate the first readable .env and parse it */
        $roots = [
            dirname(__DIR__, 2),  // /var/www/axialy-ui
            dirname(__DIR__, 3),  // one directory higher (cron executions, etc.)
        ];
        foreach ($roots as $root) {
            $envFile = $root . '/.env';
            if (!is_readable($envFile)) {
                continue;
            }

            foreach (
                file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES)
                as $line
            ) {
                if ($line === '' || $line[0] === '#' || !str_contains($line, '=')) {
                    continue;
                }
                [$k, $v] = array_map('trim', explode('=', $line, 2));

                /* back-fill only (never overwrite existing real env vars) */
                if ($k !== '' && getenv($k) === false) {
                    putenv("$k=$v");
                }
            }

            /* update cache for still-null keys */
            foreach (self::MAP as $key => $env) {
                if ($this->cache[$key] === null && getenv($env) !== false) {
                    $this->cache[$key] = getenv($env);
                }
            }
            break;  // stop after first .env found
        }
    }

    /* ───────── public API ───────── */
    public static function getInstance(): self
    {
        return self::$instance ??= new self();
    }

    public function get(string $key): ?string
    {
        return $this->cache[$key] ?? null;
    }

    /* ArrayAccess (read-only) */
    public function offsetExists($offset): bool
    {
        return array_key_exists($offset, $this->cache);
    }
    public function offsetGet($offset): mixed
    {
        return $this->cache[$offset] ?? null;
    }
    public function offsetSet($offset, $value): void
    {
        throw new \RuntimeException('Config is read-only');
    }
    public function offsetUnset($offset): void
    {
        throw new \RuntimeException('Config is read-only');
    }

    private function __clone() {}
    public function __wakeup(): void
    {
        throw new \RuntimeException('Cannot unserialise singleton');
    }
}
