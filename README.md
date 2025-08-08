# Универсальный HTTPS шлюз на Nginx и Docker

Этот проект предоставляет готовый к использованию, универсальный reverse-proxy шлюз. Он может работать в двух режимах:
1.  Production: С реальными доменами и автоматическими SSL-сертификатами от Let's Encrypt.
2.  Локальная разработка: С localhost или кастомными локальными доменами (`.local`, `.test`) и самоподписанными сертификатами для разработки без интернета.

---

## Режим 1: Production (с реальными доменами и Let's Encrypt)

> Этот режим предназначен для развертывания ваших приложений на сервере с публичным IP-адресом.

### Шаг 1: Первоначальная настройка (один раз на сервере)

1.  Клонируйте репозиторий:
```sh
git clone ...
```

2.  Запустите скрипт настройки:
```sh
chmod +x setup.sh && ./setup.sh
```

3.  Запустите контейнеры шлюза:
```sh
docker-compose up -d
```

### Шаг 2: Подключение и запуск вашего приложения

1.  **Настройте `docker-compose.yml` вашего приложения.**

Ключевые моменты:
*   Приложению не нужно выставлять порты (`ports`) наружу. Достаточно `expose`.
*   Приложение должно быть подключено к **внешней** сети `web-gateway`.
*   Запомните имя сервиса (например, `my-awesome-app`).

**Пример `docker-compose.yml` для вашего приложения:**
```yaml
version: '3.8'

services:
    my-awesome-app: # <-- Это <SERVICE_NAME>
    build: .
    container_name: my-awesome-app-container
    restart: unless-stopped
    expose:
        - "8000" # <-- Это <SERVICE_PORT>
    networks:
        - default
        - web-gateway-net # Подключаемся к нашей общей сети

networks:
    default:
    web-gateway-net:
    external: true
    name: web-gateway # Указываем имя ранее созданной сети
```

2.  **Запустите ваше приложение:**

Из папки вашего приложения выполните:
```bash
docker-compose up -d
```


### Шаг 3: Добавление домена и получение сертификата

1.  Убедитесь, что ваш домен (например, `my-app.example.com`) указывает на IP-адрес сервера.

2.  В папке шлюза запустите:
```sh
chmod +x add-domain.sh && ./add-domain.sh my-app.example.com admin@example.com
```

### Шаг 4: Настройка проксирования

1.  Скопируйте шаблон:
```sh
cp nginx/templates/production.conf.template nginx/conf.d/my-app.example.com.conf
```

2.  Отредактируйте новый файл, заменив <DOMAIN>, <SERVICE_NAME>, <SERVICE_PORT>.

3.  Перезагрузите Nginx:
```sh
docker-compose exec nginx nginx -s reload
```

Готово! Ваш сервис доступен по `https://my-app.example.com`.

---

## Режим 2: Локальная разработка (с localhost)

Этот режим идеален для разработки и тестирования на вашем компьютере, даже без подключения к интернету.

### Шаг 1: Первоначальная настройка (один раз)

Если вы еще не делали этого для production-режима, создайте общую Docker-сеть:
```sh
docker network create web-gateway
```

### Шаг 2: Запуск стороннего сервиса (Пример с Hello World)

1.  Создайте проект для вашего приложения (например, `my-hello-world-app`).
2.  Создайте в нем `docker-compose.yml`, который подключается к сети web-gateway и открывает внутренний порт через expose. ([пример](test/docker-compose.yaml)).
3.  Запустите ваше приложение:
```sh
cd ../my-hello-world-app && docker-compose up -d
```

### Шаг 3: Настройка и запуск локального шлюза

1.  Вернитесь в папку https-gateway.
2.  Сгенерируйте локальный сертификат для localhost:

```sh
chmod +x generate-local-cert.sh
./generate-local-cert.sh localhost
```

В папке nginx/ssl/ появятся файлы localhost.key и localhost.crt.

3.  Создайте конфигурацию Nginx для проксирования на ваш сервис.

```sh
cp nginx/templates/local.conf.template nginx/conf.d/localhost.conf
```

4.  Отредактируйте `nginx/conf.d/localhost.conf`. Замените плейсхолдеры:

*   <DOMAIN> -> localhost
*   <SERVICE_NAME> -> hello-app (из docker-compose.yml вашего сервиса)
*   <SERVICE_PORT> -> 80 (из expose вашего сервиса)

5.  Запустите шлюз в локальном режиме, используя специальный compose-файл:

```sh
docker-compose -f docker-compose.local.yml up -d
```

### Шаг 4: Проверка

Откройте в браузере `https://localhost`. Вы увидите предупреждение безопасности (это нормально, т.к. сертификат самоподписанный). Нажмите "Продолжить" и вы увидите страницу вашего сервиса.

Чтобы остановить локальный шлюз:
```sh
docker-compose -f docker-compose.local.yml down
```
