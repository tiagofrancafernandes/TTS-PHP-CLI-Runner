#!/bin/env php

<?php

use Symfony\Component\Process\Process;
use Symfony\Component\Process\ExecutableFinder;

require_once __DIR__ . '/vendor/autoload.php';

$ARGS = [];
$_SERVER = array_merge(
    $_SERVER ?? [],
    getenv() ?: [],
);

function array_map_with_keys(array $array, \Closure $mapFunction): array
{
    $newArray = [];
    foreach ($array as $key => $value) {
        $result = $mapFunction($key, $value);
        $result = is_array($result) ? $result : [];
        $newArray[] = [
            array_is_list($result) ? $key : array_key_first($result),
            $result[array_is_list($result) ? 0 : array_key_first($result)] ?? null
        ];
    }

    foreach ($newArray as $_key => $item) {
        [$key, $value] = $item;

        unset($newArray[$_key]);
        $newArray[$key] = $value;
    }

    return (array) $newArray;
}

function getServer(?string $key = null, mixed $default = null): mixed
{
    global $_SERVER;

    if (is_null($key)) {
        return $_SERVER ?? [];
    }

    return $_SERVER[$key] ?? $default;
}

function getArgType(?string $arg, null|string|int $key = null)
{
    $arg = trim(strval($arg));

    if (!$arg || !str_starts_with($arg, '--')) {
        return [
            'type' => 'general',
            'key' => $key,
            'value' => $arg,
        ];
    }

    if (preg_match("/^--.*=/", $arg)) {
        $_arg = explode('=', $arg, 2);

        return [
            'type' => 'key-value',
            'key' => $_arg[0] ?? $key ?? null,
            'alter_key' => $key ?? $_arg[0] ?? null,
            'value' => $_arg[1] ?? $arg,
        ];
    }

    return [
        'type' => 'bool',
        'key' => $arg,
        'alter_key' => $key,
        'value' => true,
    ];
}

function formatArgs(): void
{
    global $argv;
    global $ARGS;

    $ARGS = [];
    $ARGS['argv'] = [
        'type' => 'key-value',
        'key' => $argv,
        'alter_key' => '--argv',
        'value' => $argv,
    ];

    foreach ($argv as $key => $arg) {
        $argData = getArgType($arg, $key);
        $key = $argData['key'] ?? $argData['alter_key'] ?? $key;
        $ARGS[$key] = $argData;
    }
}

formatArgs();

function getArgs(): array
{
    global $ARGS;

    return $ARGS ?? [];
}

function getArg(string|int $key, mixed $default = null): mixed
{
    return getArgs()[$key]['value'] ?? $default;
}

$timezone = $_SERVER['TZ'] ?? 'America/Sao_Paulo';
date_default_timezone_set($timezone);

function readStdinNonBlocking(): ?string
{
    if (function_exists('posix_isatty') && posix_isatty(STDIN)) {
        return null;
    }

    stream_set_blocking(STDIN, false);

    $read = [STDIN];
    $write = null;
    $except = null;

    if (stream_select($read, $write, $except, 0, 200000) === 0) {
        return null;
    }

    return stream_get_contents(STDIN);
}

function getStdin(): string
{
    $content = readStdinNonBlocking() ?: '';
    return trim($content);
}

function logToFile(...$content)
{
    file_put_contents(
        __DIR__ . '/log.log',
        '[' . date('c') . ']' . json_encode($content, 64) . PHP_EOL,
        FILE_APPEND
    );
}

function killByPid(int $pid)
{
    try {
        $process = new Process(['kill', '-9', $pid]);
        $process->run();

        return $process->stop(7, SIGINT);
    } catch (\Throwable $th) {
        throw $th;
    }
}

function trueOrFalse(
    mixed $value = null,
    ?bool $defaultValue = false,
): bool {
    try {
        return match (trim(strtoupper(json_encode($value)), ' \'\"')) {
            '=VERDADEIRO()', '=TRUE()', 'VERDADEIRO()', 'TRUE()' => true, // excel true values
            'Y', 'YES', 'V', 'VERDADEIRO', 'S', 'SIM', '1', 'T', 'TRUE' => true,
            'N', 'NO', 'F', 'FALSO', '', 'NULL', 'NULO', 'NÃO', 'NAO', '0', 'FALSE' => false,
            '!Y', '!YES', '!V', '!VERDADEIRO', '!S', '!SIM', '!1', '!T', '!TRUE' => false,
            default => $defaultValue,
        }
            ?? filter_var($value, FILTER_VALIDATE_BOOL);
    } catch (\Exception $e) {
        return $defaultValue ?? false;
    }
}

function closeOtherInstances(string $searchBy = '')
{
    // if (!trim($searchBy)) {
    //     return false;
    // }

    $searchBy = trim($searchBy) ? '| grep ' . trim($searchBy) : '';

    $process = new Process([
        'bash',
        '-c',
        "ps aux {$searchBy} |grep 'speak\.php\.sh' | grep -v grep | awk '{print \$2}'",
    ]);
    $process->run();

    foreach ($process as $type => $data) {
        if ($process::OUT === $type) {
            foreach (explode(PHP_EOL, $data) as $item) {
                $item = trim($item);

                if (!$item) {
                    continue;
                }

                $pid = is_numeric(trim($item)) ? (int) trim($item) : null;

                if (!$pid) {
                    continue;
                }

                echo "Killing by PID: |{$pid}|" . PHP_EOL;

                killByPid((int) $pid);
            }

            continue;
        }

        // $process::ERR === $type
        echo "\n[ERROR] Read from stderr: " . $data . PHP_EOL;
    }
    $process->stop(3, SIGINT);
    // $process->signal(SIGKILL);
}

function downloadTo(string $url, string $to)
{
    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

    $fileData = curl_exec($ch);

    ## curl_close is deprecated since PHP 8.5
    if (PHP_VERSION_ID < 80500) {
        /** @suppress PHP6403 */
        curl_close($ch);
    }

    $fp = fopen($to, 'w');
    fwrite($fp, $fileData);
    fclose($fp);

    return $to;
}

function run(string $text)
{
    $oneInstance = trueOrFalse(getArg('--one-instance', getServer('ONE_INSTANCE', false)));
    $params = [
        '--advanced',
        '--one-instance' => !$oneInstance,
        '--play-and-exit',
        '--no-start-paused',
        '--no-repeat',
        '--no-loop',
        '--no-random',
        '--no-autoscale',
        '--no-video-on-top',
        '--no-keyboard-events',
        '--no-fullscreen',
        '--no-video',
        '--no-mouse-events',
    ];

    $params = array_keys(array_filter(array_map_with_keys($params, function ($key, $value) {
        $nkey = is_integer($key) && is_string($value) ? $value : $key;
        return [$nkey => $value];
    })));

    $programs = [
        'vlc' => [
            'paths' => [
                'name' => 'cvlc',
                'default' => '/usr/bin/cvlc',
                'extraDirs' => [],
            ],
            'params' => $params,
        ],
        'carbonyl' => [
            'paths' => [
                'name' => 'carbonyl',
                'default' => '/usr/bin/carbonyl',
                'extraDirs' => ['local-bin/carbonyl'],
            ],
            'params' => [],
        ],
    ];

    $execName = 'vlc';
    try {
        if (!($programs[$execName]['paths'] ?? null)) {
            echo verboseMode() ? "Invalid program ['{$execName}']" . PHP_EOL : '';
            return;
        }

        closeOtherInstances($execName);
        $executableFinder = new ExecutableFinder();

        $executablePath = $executableFinder->find(
            $programs[$execName]['paths']['name'] ?? null,
            $programs[$execName]['paths']['default'] ?? null,
            $programs[$execName]['paths']['extraDirs'] ?? null,
        );

        // https://translate.googleapis.com/translate_tts?client=gtx&q=Foco%20no%20essencial%2C%20depois%20voc%C3%AA%20ajusta%20o%20restante&tl=pt&ttsspeed=0.8&tk=783660.873733

        if (!file_exists($executablePath)) {
            throw new \Exception("The file '{$executablePath}' not exists", 1);
        }

        $baseUrl = 'https://translate.googleapis.com/translate_tts';

        $replacements = [
            '  ' => ' ',
        ];

        $text = str_replace(array_keys($replacements), array_values($replacements), $text);

        $getSpeed = function ($value) {
            $value = is_numeric($value) ? floatval($value) : 1.0;
            return $value >= 0 && $value <= 1 ? floatval($value) : 1.0;
        };

        $speed = $getSpeed(getArg('--speed', getServer('TTS_SPEED', 1.0)));

        $locale = getArg('--locale', null);

        if (!$locale || !is_string($locale)) {
            $_tmp_srv = getServer();
            $locale = $_tmp_srv['TTS_LOCALE'] ?? $_tmp_srv['LC_ALL'] ?? $_tmp_srv['LANGUAGE'] ?? 'en';
            $locale = explode('.', trim($locale), 2)[0] ?? null;
            unset($_tmp_srv);
        }

        $locale = is_string($locale) ? $locale : 'en';

        $query = http_build_query([
            'client' => 'gtx',
            'q' => trim("{$text}"),
            'tl' => $locale,
            'ttsspeed' => $speed,
            'tk' => 783660.873733,
            'program_id' => 'speak.php.sh',
        ]);

        $url = "{$baseUrl}?{$query}";

        // $fileName = md5($url);
        $fileName = str_replace(
            [
                PHP_EOL,
                ' ',
                '_',
                '.',
                ',',
                ';',
                ':',
            ],
            '-',
            trim($text)
        );

        $tempDir = sys_get_temp_dir() ?: '/tmp';

        $localFilePath = "{$tempDir}/speak-php-{$fileName}-{$locale}.mp3";

        if (!is_file($localFilePath)) {
            // file_put_contents($localFilePath, file_get_contents($url));
            downloadTo($url, $localFilePath);

            chmod($localFilePath, 777);
        }

        // $process = new Process([$executablePath, $url]);

        $params = array_merge([
            $executablePath,
            ...($programs[$execName]['params'] ?? []),
            realpath($localFilePath),
        ]);

        $process = new Process($params);
        // $process->disableOutput();

        $timeout = (substr_count($text, ' ') ?: 10);
        $timeout = $timeout >= 10 ? $timeout : 10;
        $process->setTimeout($timeout);

        $process->run();
        $process->stop($timeout, SIGINT);
    } catch (\Throwable $th) {
        //

        closeOtherInstances($execName);
    }
}

function verboseMode(): bool
{
    return trueOrFalse(getServer('VERBOSE', getArg('--verbose', false)));
}

$toReadStdin = trueOrFalse($_SERVER['TO_READ_STDIN'] ?? getArg('--stdin'), false);

// $text = $toReadStdin ? getStdin() : $_SERVER['TEXT_TO_SAY'] ?? readStdinNonBlocking() ?? implode(
//     ' ',
//     array_slice($argv, 1)
// );

$text = readStdinNonBlocking();

$toEval = $_SERVER['TO_EVAL'] ?? null;

$text = trim("{$text}");

if (!$text && !is_string($toEval)) {
    die(verboseMode() ? 'No text to say' . PHP_EOL : '');
}

$manyTimes = filter_var($_SERVER['MANY_TIMES'] ?? null, FILTER_VALIDATE_INT) ?: null;
$manyTimes ??= $toReadStdin ? 1 : null;

$manyTimes = is_numeric($manyTimes) ? intval($manyTimes) : null;

$sleepSeconds = $_SERVER['SLEEP'] ?? 300;
$sleepSeconds = is_numeric($sleepSeconds) && boolval($sleepSeconds >= 1) ? (int) $sleepSeconds : 300;

$once = trueOrFalse($_SERVER['ONCE'] ?? getArg('--once') ?? false, null);
$toSayCounter = trueOrFalse(getArg('--verbose') ?? $_SERVER['TO_SAY_COUNTER'] ?? false);

$manyTimes = $once ? 1 : $manyTimes;

$runCounter = 0;

while (true) {
    if (is_string($toEval)) {
        eval ("\$text = {$toEval};");
    }

    $runCounter++;

    if (verboseMode()) {
        echo json_encode($text, 64) . PHP_EOL;
        echo "Run counter: {$runCounter}" . (
            $manyTimes ? " of {$manyTimes} " : ""
        ) . PHP_EOL;
    }

    run($text);

    if ($toSayCounter) {
        run("Contador em {$runCounter}");
    }

    if ($manyTimes && ($runCounter >= $manyTimes)) {
        break;
    }

    if (verboseMode()) {
        echo PHP_EOL . "Sleeping for {$sleepSeconds} seconds" . PHP_EOL;
    }

    sleep($sleepSeconds);
}
