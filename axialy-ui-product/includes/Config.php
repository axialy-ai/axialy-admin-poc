<?php
/**
 * Lightweight, env-variable-driven configuration helper for Axialy-UI
 *
 * Mirrors the Admin-side helper so that older code can still do:
 *   $cfg = \AxiaBA\Config\Config::getInstance();
 *   $cfg->get('app_base_url');
 *
 * ────────── WHAT CHANGED? ──────────
 *  • Added smtp_* keys so mailer.php can pull credentials.
 *  • No original keys or behaviour were removed.
 */
namespace AxiaBA\Config;

final class Config implements \ArrayAccess
{
    /** singleton */
    private static ?self $instance = null;

    /** cached key ⇒ value */
    private array $cache = [];

    private function __construct()
    {
        /* map logical keys ➜ environment variables */
        $map = [
            // database (UI)
            'db_host'               => 'UI_DB_HOST',
            'db_name'               => 'UI_DB_NAME',
            'db_user'               => 'UI_DB_USER',
            'db_password'           => 'UI_DB_PASSWORD',

            // misc services
            'api_base_url'          => 'API_BASE_URL',
            'app_base_url'          => 'APP_BASE_URL',
            'internal_api_key'      => 'INTERNAL_API_KEY',

            // Stripe
            'stripe_api_key'        => 'STRIPE_API_KEY',
            'stripe_publishable_key'=> 'STRIPE_PUBLISHABLE_KEY',
            'stripe_webhook_secret' => 'STRIPE_WEBHOOK_SECRET',

            // SMTP (NEW)
            'smtp_host'             => 'SMTP_HOST',
            'smtp_port'             => 'SMTP_PORT',
            'smtp_user'             => 'SMTP_USER',
            'smtp_password'         => 'SMTP_PASSWORD',
            'smtp_from_address'     => 'SMTP_FROM_ADDRESS',
            'smtp_from_name'        => 'SMTP_FROM_NAME',

            // misc
            'app_version'           => 'APP_VERSION',
        ];

        /* prime cache from real environment */
        foreach ($map as $k => $env) {
            $this->cache[$k] = getenv($env) !== false ? getenv($env) : null;
        }

        /* local-dev fallback: parse nearest .env if nothing set */
        if (!array_filter($this->cache)) {
            $candidates = [
                dirname(__DIR__, 2).'/.env',
                dirname(__DIR__, 3).'/.env',
            ];
            foreach ($candidates as $file) {
                if (!is_readable($file)) continue;

                foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
                    if ($line[0] === '#' || !str_contains($line, '=')) continue;
                    [$k, $v] = array_map('trim', explode('=', $line, 2));
                    if ($k && getenv($k) === false) {
                        putenv("$k=$v");
                    }
                }

                /* reload the env vars we care about */
                foreach ($map as $k => $env) {
                    if ($this->cache[$k] === null && getenv($env) !== false) {
                        $this->cache[$k] = getenv($env);
                    }
                }
                break; // stop after first readable .env
            }
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

    /* ArrayAccess so older `$config['db_host']` style still works */
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
