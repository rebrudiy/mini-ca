# Отчёт: Мини-УЦ на основе OpenSSL

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

#### Шаг 1.4 — Запрос на сертификат (CSR) Intermediate CA

```bash
openssl req -new -key ca/intermediate.key -out ca/intermediate.csr -subj "/CN=Mini Intermediate CA/O=Mini CA/C=RU"
```
- `req -new` — создать CSR
- `-key ca/intermediate.key` — приватный ключ Intermediate CA
- `-out ca/intermediate.csr` — файл назначения

#### Шаг 1.5 — Подпись Intermediate CA сертификата корневым CA

```bash
openssl x509 -req -days 1825 -in ca/intermediate.csr -CA ca/root.crt -CAkey ca/root.key -CAcreateserial -out ca/intermediate.crt
```
- `x509 -req` — подписать CSR
- `-days 1825` — срок действия 5 лет (меньше чем у Root)
- `-CA ca/root.crt` — сертификат Root CA (издатель)
- `-CAkey ca/root.key` — приватный ключ Root CA
- `-CAcreateserial` — автоматически создать файл серийных номеров

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

### 3. HTTPS-соединение

### 4. Отзыв сертификата
