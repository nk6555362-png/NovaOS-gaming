# NovaOS Gaming — GitHub Actions bootstrap

Начальный проект кастомного Arch Linux ISO для Lenovo IdeaPad Gaming 3 15IMH05:
Intel Core i5-10300H, NVIDIA GTX 1650 Ti 4 ГБ и Intel UHD Graphics.

## Сборка со смартфона Android

1. Скачайте ZIP и распакуйте его на телефоне.
2. Создайте пустой репозиторий на https://github.com/new, например `NovaOS-Gaming`.
3. Загрузите **все** файлы и папки из архива в корень репозитория. Обязательно сохраните `.github/workflows/build-iso.yml`.
   В мобильном браузере может понадобиться режим «Версия для ПК».
4. Откройте вкладку **Actions** в репозитории и разрешите workflows, если GitHub попросит.
5. Выберите `Build NovaOS Gaming ISO` → `Run workflow` → `Run workflow`.
6. Откройте завершившийся запуск и скачайте artifact `novaos-gaming-iso`. В нём будут ISO и `SHA256SUMS`.

## Что делает workflow

GitHub Actions запускает Arch Linux container, устанавливает `archiso`, копирует официальный профиль `releng`, добавляет пакеты NovaOS и запускает `mkarchiso`. Готовый ISO публикуется как временный artifact на 7 дней.

## Важные ограничения

- Archiso рассчитан прежде всего на сборку в Arch Linux. Workflow использует привилегированный контейнер, но если GitHub-hosted runner ограничит mount/namespace, сборка может упасть. Тогда понадобится отдельный Arch Linux VPS или self-hosted runner.
- Это **первый загрузочный bootstrap ISO**, а не готовый релиз. В нём будут пакеты KDE/Steam, но автоматический запуск графической live-сессии, фирменная тема, автологин и графический установщик ещё не реализованы.
- Пакеты могут изменяться в репозиториях Arch. Если сборка остановится на конкретном пакете, посмотрите логи Actions и исправьте `packages.extra`.
- ISO не изменяет ваш ноутбук или Windows при сборке. Разметка диска происходит только если вы сами позже запустите установку.
- Перед установкой рядом с Windows сделайте резервную копию, сохраните ключ BitLocker при включённом шифровании и не форматируйте существующий EFI-раздел.

## Локальная сборка

На полноценной актуальной Arch Linux системе с `archiso`:
```bash
sudo pacman -Syu --needed archiso
bash scripts/ci-build-iso.sh
```
