# TTS PHP CLI Runner

### Usage

```sh
echo "PHP is amazing!" | /usr/bin/speak.php.sh --stdin --locale=en
```

```sh
PHRASE="PHP é demais!"; MIN=1; TZ=America/Sao_Paulo SLEEP=$(php -r "echo ${MIN} * 60;") TO_EVAL="'${PHRASE}'" /usr/bin/speak.php.sh
```

```sh
FRASE='projeto vitrine'; SLEEP=60; export MANY_TIMES=0; export TO_SAY_COUNTER=1; MIN=1; TZ=America/Sao_Paulo SLEEP=${SLEEP} TO_EVAL="\"${FRASE}\"" /usr/bin/speak.php.sh
```
