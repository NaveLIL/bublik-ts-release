# Bublik Bot

[![Distribution CI](https://github.com/NaveLIL/bublik-ts/actions/workflows/distribution-ci.yml/badge.svg)](https://github.com/NaveLIL/bublik-ts/actions/workflows/distribution-ci.yml)

Bublik — модульный Discord-бот для управления сообществом: полковые бои War Thunder, голосовые каналы, команды, экономика, онбординг, отпуска и расписание боевых рейтингов.

Этот публичный репозиторий является **distribution-репозиторием**. Он содержит проверенный обфусцированный runtime, миграции базы, локализации и конфигурацию запуска. Исходный TypeScript, тесты и внутренние production-runbook сюда не публикуются.

> Обфускация затрудняет поверхностное чтение кода, но не заменяет контроль доступа, безопасное хранение секретов и своевременное обновление зависимостей.

## Состав релиза

- `dist-protected/` — обфусцированный runtime без source map, деклараций и тестов;
- `artifact-manifest.json` — точный список файлов, размеры и SHA-256;
- `prisma/` — схема и последовательные production-миграции;
- `locales/` — русская и английская локализации;
- `Dockerfile` и `docker-compose.yml` — поддерживаемый способ запуска;
- `scripts/` — только необходимые runtime- и migration-проверки.

Полные TypeScript-, ESLint- и модульные проверки выполняются до экспорта. Публичный CI повторно проверяет manifest, синтаксис runtime, зависимости, миграции и итоговый Docker-образ.

## Требования

- Docker Engine с Compose v2;
- Discord Application с bot token и нужными privileged intents;
- PostgreSQL 16 и Redis 7, создаваемые предоставленным Compose-файлом;
- постоянное хранилище для PostgreSQL и Redis.

Node.js 24 требуется только для локальной проверки distribution без Docker.

## Быстрый запуск

```bash
cp .env.example .env
# Заполните DISCORD_TOKEN, DISCORD_CLIENT_ID и сильный POSTGRES_PASSWORD.

docker compose config --quiet
npm ci --omit=dev --ignore-scripts --no-audit
npm run verify:distribution
docker compose up -d --build
docker compose ps
```

Логи бота:

```bash
docker compose logs --tail=200 bot
```

Рабочие `.env`, дампы и каталоги данных нельзя коммитить или прикладывать к issue.

## Данные и обновления

Compose использует именованные volumes:

- `bublik-n_pg_data` — PostgreSQL;
- `bublik-n_redis_data` — Redis/AOF;
- `bublik-n_logs_data` — журналы бота с корректными правами для non-root процесса.

Никогда не выполняйте `docker compose down -v` при обычном обновлении: ключ `-v` удаляет volumes с данными.

Перед сменой версии:

1. Зафиксируйте текущий image digest и конфигурацию.
2. Создайте и проверьте резервную копию PostgreSQL и Redis.
3. Прочитайте changelog и список миграций.
4. Проверьте новый manifest и образ.
5. Выполните обновление в окно обслуживания.
6. Проверьте healthcheck, логи, команды и критические ПБ-сценарии.

Entrypoint применяет только последовательные `prisma migrate deploy`. `PRISMA_BASELINE_EXISTING=1` допустим исключительно как разовый override команды отдельного migration-only контейнера для первой контролируемой миграции старой базы, ранее созданной через `db push`. В постоянный `.env` этот флаг не записывается; обычный сервис бота всегда запускается со значением `0`.

## Проверка артефакта

```bash
npm ci --omit=dev --ignore-scripts --no-audit
npm run verify:distribution
npm run audit:runtime
docker build --tag bublik-runtime:local .
```

Проверка завершается ошибкой при лишнем или отсутствующем runtime-файле, несовпадении SHA-256, наличии `src/`, TypeScript, тестов, source map, symlink, секретоподобного содержимого или синтаксически неверного JavaScript.

## Релизы

- `main` содержит следующую проверенную distribution-версию;
- production-релизы получают тег `vMAJOR.MINOR.PATCH`;
- Docker-образ должен разворачиваться по неизменяемому digest, а не по `latest`;
- изменение `dist-protected/` без соответствующего manifest не принимается;
- автоматическая выкладка из публичного GitHub на VPS не выполняется.

## Поддержка и безопасность

- [Отчёт об ошибке](https://github.com/NaveLIL/bublik-ts/issues/new?template=bug.yml)
- [Предложение функции](https://github.com/NaveLIL/bublik-ts/issues/new?template=feature.yml)
- [Правила поддержки](SUPPORT.md)
- [Приватный отчёт об уязвимости](SECURITY.md)
- [Правила участия](CONTRIBUTING.md)
- [Журнал изменений](CHANGELOG.md)

Пакет помечен как `UNLICENSED`. Публичная доступность distribution не означает публикацию исходного кода или переход проекта на open-source модель.
