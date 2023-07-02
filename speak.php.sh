#!/bin/env php

<?php
use Symfony\Component\Process\Process;

$process = new Process(['/usr/bin/php', 'worker.php']);
$process->disableOutput();
$process->run();
