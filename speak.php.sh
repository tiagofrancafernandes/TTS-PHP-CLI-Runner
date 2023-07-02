#!/bin/env php

<?php

use Symfony\Component\Process\Process;
use Symfony\Component\Process\ExecutableFinder;

require_once __DIR__ . '/vendor/autoload.php';

$logToFile = fn (...$content) => file_put_contents(
    __DIR__ . '/log.log',
    '[' . date('c') . ']' . json_encode($content, 64) . PHP_EOL,
    FILE_APPEND
);

try {
    $executableFinder = new ExecutableFinder();
    $carbonylPath = $executableFinder->find(
        'carbonyl',
        '/usr/bin/carbonyl',
        ['local-bin/carbonyl'],
    );

    // https://translate.googleapis.com/translate_tts?client=gtx&q=Foco%20no%20essencial%2C%20depois%20voc%C3%AA%20ajusta%20o%20restante&tl=pt&ttsspeed=0.8&tk=783660.873733

    if (!file_exists($carbonylPath)) {
        throw new \Exception("The file '{$carbonylPath}' not exists", 1);
    }

    $baseUrl = 'https://translate.googleapis.com/translate_tts';

    $replacements = [
        '  ' => ' ',
    ];

    $text = 'Foco no essencial, depois você ajusta o restante';

    $text = str_replace(array_keys($replacements), array_values($replacements), $text);

    $query = http_build_query([
        'client' => 'gtx',
        'q' => $text,
        'tl' => 'pt',
        'ttsspeed' => 0.8,
        'tk' => 783660.873733,
        'program_id' => 'speak.php.sh',
    ]);

    $url = "{$baseUrl}?{$query}";

    $process = new Process([$carbonylPath, $url]);
    $process->disableOutput();

    $timeout = substr_count($text, ' ') ?: 5;
    $process->setTimeout($timeout);

    $process->run();
} catch (\Throwable $th) {
    // $logToFile($th->getMessage());
}
