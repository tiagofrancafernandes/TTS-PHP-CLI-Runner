# TTS PHP CLI Runner

See the [Portuguese version](README.pt.md).

## Overview

`/usr/bin/speak.php.sh` turns CLI text into speech by downloading a cached mp3 from Google Translate TTS and playing it with `cvlc`. It parses CLI flags, environment variables, and optionally evaluates `TO_EVAL` expressions before each speak cycle.

## Requirements

- PHP 8.2+ (matching the Symfony `Process` dependency in `composer.json`)
- `composer install` to fetch `symfony/process`
- `cvlc` (VLC console player) installed and on `PATH`

## Installation

```bash
composer install
```

## Usage

The script can read from stdin, environment variables, or evaluated PHP expressions:

```bash
echo "PHP is amazing!" | ./speak.php.sh --stdin --locale=en --speed=0.9
```

You can also inject dynamic text via `TO_EVAL`:

```bash
SLEEP=60 TO_EVAL='"Hello number " . rand(1, 100)' ./speak.php.sh
```

### Looping and repetition

- `MANY_TIMES`: if numeric, the loop runs that many times (inferred from env or CLI). Defaults to 1 when reading from stdin.
- `ONCE`: forces a single iteration regardless of other counters.
- `SLEEP`: seconds to wait after each run before repeating (default 300). Values <1 fall back to 300.
- `TO_SAY_COUNTER`: when truthy, the script calls `run("Contador em {run}")` after each play to announce the counter in Portuguese.

When the loop is enabled, the script increments `run` and stops once `MANY_TIMES` iterations are reached or when `ONCE` is set.

## Flags and env overrides

- `--locale` / `TTS_LOCALE`: fallback to `LANGUAGE`/`LC_ALL`; defaults to `en`.
- `--speed` / `TTS_SPEED`: float between 0 and 1.
- `--verbose` / `VERBOSE`: enables logging of the text and counter.
- `--one-instance`: toggles `cvlc`'s `--one-instance` flag (defaults to `false`).
- `--stdin`: currently ignored because stdin reading already runs unconditionally.

## Testing

- `composer install` (already required for the runtime helpers) installs PHPUnit.
- `composer test` or `vendor/bin/phpunit` executes the helper tests defined in `tests/`.

## Notes

- The script caches the mp3 in `sys_get_temp_dir()` with a sanitized file name and sets permissions to `777` for reuse.
- `TO_EVAL` uses `eval`; only use trusted expressions.
- Running multiple instances closes existing `speak.php.sh` processes by PID before starting a new one.
