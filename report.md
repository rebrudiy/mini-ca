# Отчёт: Мини-УЦ на основе OpenSSL

**Исходный код:** [github.com/rebrudiy/mini-ca](https://github.com/rebrudiy/mini-ca)

## Обзор

В данной работе моделируется инфраструктура открытых ключей (PKI), состоящая из трёх участников:

- **УЦ (удостоверяющий центр)** — выдаёт и отзывает сертификаты.
- **Сервер** — получает сертификат от УЦ и принимает HTTPS-соединения.
- **Клиент** — устанавливает соединение только с серверами, сертификат которых подписан нашим УЦ.

## Шаги

### 1. Настройка УЦ (CA)

#### Шаг 1.1 — Генерация приватного ключа Root CA

```bash
openssl genrsa -out ca/root.key 4096
```
- `genrsa` — генерирует приватный ключ по алгоритму RSA
- `4096` — длина ключа в битах
- `-out ca/root.key` — файл назначения

#### Шаг 1.2 — Генерация Root CA

```bash
openssl req -new -x509 -days 3650 -key ca/root.key -out ca/root.crt -subj "/CN=Mini Root CA/O=Mini CA/C=RU"
```
- `req -new` — создать новый запрос на сертификат
- `-x509` — сделать сертификат самоподписанным
- `-days 3650` — срок действия 10 лет
- `-key ca/root.key` — приватный ключ для подписи
- `-out ca/root.crt` — файл назначения
- `-subj` — идентификационные данные без интерактивного ввода

#### Шаг 1.3 — Генерация приватного ключа Intermediate CA

```bash
openssl genrsa -out ca/intermediate.key 4096
```
- `genrsa` — генерирует приватный ключ по алгоритму RSA
- `4096` — длина ключа в битах
- `-out ca/intermediate.key` — файл назначения

#### Шаг 1.4 — Запрос на сертификат (CSR) Intermediate CA

```bash
openssl req -new -key ca/intermediate.key -out ca/intermediate.csr -subj "/CN=Mini Intermediate CA/O=Mini CA/C=RU"
```
- `req -new` — создать CSR
- `-key ca/intermediate.key` — приватный ключ Intermediate CA
- `-out ca/intermediate.csr` — файл назначения
- `-subj` — идентификационные данные без интерактивного ввода

#### Шаг 1.5 — Подпись Intermediate CA сертификата корневым CA

```bash
openssl x509 -req -days 1825 -in ca/intermediate.csr -CA ca/root.crt -CAkey ca/root.key -CAcreateserial -out ca/intermediate.crt -extfile <(echo -e "basicConstraints=CA:TRUE\nkeyUsage=keyCertSign,cRLSign")
```
- `x509 -req` — подписать CSR
- `-days 1825` — срок действия 5 лет (меньше чем у Root)
- `-CA ca/root.crt` — сертификат Root CA (издатель)
- `-CAkey ca/root.key` — приватный ключ Root CA
- `-CAcreateserial` — автоматически создать файл серийных номеров
- `-extfile` — файл с расширениями сертификата
- `basicConstraints=CA:TRUE` — указывает что это CA-сертификат, без этого флага OpenSSL не признаёт его валидным CA
- `keyUsage=keyCertSign,cRLSign` — разрешает подписывать сертификаты и CRL

#### Шаг 1.6 — Инициализация базы данных CA

```bash
touch ca/index.txt && echo "1000" > ca/serial && echo "1000" > ca/crlnumber
```
- `index.txt` — база данных выданных и отозванных сертификатов
- `serial` — текущий серийный номер
- `crlnumber` — текущий номер CRL

#### Шаг 1.7 — Передача Root CA сертификата клиенту

```bash
cp ca/root.crt client/root.crt
```

В реальном окружении сертификат Root CA предустановлен в операционной системе или браузере (trust store). В данной симуляции мы вручную копируем `root.crt` в папку клиента — это эквивалент доверенного хранилища.

### 2. Сертификат сервера

#### Шаг 2.1 — Генерация приватного ключа сервера

```bash
openssl genrsa -out server/server.key 2048
```
- `genrsa` — генерирует приватный ключ RSA
- `2048` — длина ключа (достаточно для сервера с коротким сроком действия)
- `-out server/server.key` — файл назначения

#### Шаг 2.2 — Создание CSR (запрос на сертификат)

```bash
openssl req -new -key server/server.key -out server/server.csr -subj "/CN=localhost/O=Mini CA/C=RU"
```
- `req -new` — создать CSR
- `-key server/server.key` — приватный ключ сервера
- `-out server/server.csr` — файл назначения
- `CN=localhost` — должен совпадать с адресом сервера, иначе клиент отклонит сертификат

#### Шаг 2.3 — Подпись сертификата сервера Intermediate CA

```bash
openssl x509 -req -days 365 -in server/server.csr -CA ca/intermediate.crt -CAkey ca/intermediate.key -CAcreateserial -out server/server.crt
```
- `x509 -req` — подписать CSR
- `-days 365` — срок действия 1 год
- `-CA ca/intermediate.crt` — сертификат Intermediate CA (издатель)
- `-CAkey ca/intermediate.key` — приватный ключ Intermediate CA
- `-CAcreateserial` — автоматически создать файл серийных номеров

### 3. HTTPS-соединение

#### Шаг 3.1 — Запуск HTTPS-сервера

```bash
openssl s_server -accept 4433 -cert server/server.crt -key server/server.key -cert_chain ca/intermediate.crt -www
```
- `-accept 4433` — порт сервера
- `-cert server/server.crt` — сертификат сервера
- `-key server/server.key` — приватный ключ сервера
- `-cert_chain ca/intermediate.crt` — цепочка сертификатов (intermediate CA)
- `-www` — отдаёт статус страницу при подключении

#### Шаг 3.2 — Подключение к google.com (ожидаем ошибку)

```bash
bash client/verify.sh google.com:443
```

**Вывод:**
```
=== Подключение к google.com:443 ===
verify error:num=20:unable to get local issuer certificate
Verification error: unable to get local issuer certificate
Verify return code: 20 (unable to get local issuer certificate)
```
Ошибка ожидаема — сертификат google.com подписан публичным CA, которому наш клиент не доверяет.

#### Шаг 3.3 — Подключение к нашему серверу (ожидаем успех)

```bash
bash client/verify.sh localhost:4433
```

**Вывод:**
```
=== Подключение к localhost:4433 ===
Verify return code: 0 (ok)
```
Соединение установлено успешно — сертификат сервера подписан нашим Intermediate CA, который в свою очередь подписан Root CA из trust store клиента.

### 4. Отзыв сертификата

#### Шаг 4.1 — Отзыв сертификата Intermediate CA

```bash
openssl ca -config $TMPCONF -revoke ca/intermediate.crt
```
- `ca -revoke` — отозвать сертификат, добавив запись в `index.txt`
- `-config` — конфигурация CA (база данных, ключ, сертификат)
- `ca/intermediate.crt` — отзываемый сертификат

**Вывод:**
```
Adding Entry with serial number 33A2836E... to DB for /CN=Mini Intermediate CA/O=Mini CA/C=RU
Revoking Certificate 33A2836E...
Database updated
```

#### Шаг 4.2 — Генерация CRL

```bash
openssl ca -config $TMPCONF -gencrl -out ca/crl.pem
```
- `ca -gencrl` — сгенерировать список отозванных сертификатов
- `-out ca/crl.pem` — файл назначения

**Вывод:** команда выполнена без вывода, создан файл `ca/crl.pem`

#### Шаг 4.3 — Повторное подключение к серверу (ожидаем отказ)

```bash
openssl s_client -connect localhost:4433 -CAfile client/root.crt -crl_check_all -CRL ca/crl.pem
```
- `-crl_check_all` — проверять CRL для всей цепочки сертификатов
- `-CRL ca/crl.pem` — файл CRL для проверки

**Вывод:**
```
verify error:num=3:unable to get certificate CRL
verify error:num=23:certificate revoked
Verification error: certificate revoked
Verify return code: 23 (certificate revoked)
```
Соединение отклонено — Intermediate CA отозван, цепочка доверия нарушена.
