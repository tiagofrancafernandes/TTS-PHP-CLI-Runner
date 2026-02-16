# TTS PHP CLI Runner

Veja a [versão em inglês](README.md).

## Visão geral

O script `/usr/bin/speak.php.sh` transforma texto de linha de comando em voz ao baixar um MP3 do Google Translate TTS (com cache em `/tmp`) e reproduzi-lo com `cvlc`. Ele lê flags, variáveis de ambiente e pode avaliar a expressão `TO_EVAL` antes de cada execução.

## Requisitos

- PHP 8.2+ (compatível com `symfony/process` exigido em `composer.json`)
- `composer install` para instalar `symfony/process`
- `cvlc` (reprodutor de linha de comando do VLC) disponível no `PATH`

## Instalação

```bash
composer install
```

## Uso

Você pode passar texto via stdin, variáveis de ambiente ou `TO_EVAL`:

```bash
echo "PHP é demais!" | ./speak.php.sh --stdin --locale=pt --speed=0.8
```

```bash
SLEEP=60 TO_EVAL='"Alô número " . rand(1, 100)' ./speak.php.sh
```

### Loop e repetição

- `MANY_TIMES`: número de repetições do loop (0/undefined = loop infinito quando não há `TO_EVAL`). Quando o texto sai do stdin, o valor padrão é 1.
- `ONCE`: força apenas uma execução, ignorando `MANY_TIMES`.
- `SLEEP`: segundos de espera entre execuções (padrão 300). Valores menores que 1 voltam para 300.
- `TO_SAY_COUNTER`: quando verdadeiro, o script também fala `Contador em {run}` a cada ciclo.

O loop conta as execuções usando `runCounter` e encerra quando atinge `MANY_TIMES` ou se `ONCE` estiver ativo.

## Flags e variáveis

- `--locale` / `TTS_LOCALE`: usa `LANGUAGE`/`LC_ALL` como fallback; padrão `en`.
- `--speed` / `TTS_SPEED`: valor decimal entre 0 e 1 para o tempo de fala.
- `--verbose` / `VERBOSE`: mostra texto e contador no console.
- `--one-instance`: ativa/desativa `--one-instance` no `cvlc` (por padrão, desativado).
- `--stdin`: reconhecido mas o script já lê stdin de forma não bloqueante mesmo sem esse flag.

## Observações

- Os MP3s ficam em `sys_get_temp_dir()` com nome limpo e recebem permissão `777`.
- A expressão `TO_EVAL` é rodada via `eval`, portanto use apenas conteúdo confiável.
- Antes de iniciar, o script encerra outros processos `speak.php.sh` para evitar múltiplas execuções concorrentes.
