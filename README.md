# NovaOS Gaming — Arch Linux live ISO

Начальный проект кастомного Arch Linux ISO для Lenovo IdeaPad Gaming 3 15IMH05:
Intel Core i5-10300H, NVIDIA GTX 1650 Ti 4 ГБ и Intel UHD Graphics.

## Live-система и установка

ISO загружает KDE Plasma через SDDM в live-среду под временным пользователем nova-live.
На рабочем столе есть ярлык **Install NovaOS Gaming** для графического установщика Calamares.
В установщике начальный выбор диска не задан: проверьте выбранный диск и разметку перед подтверждением.
Для установки рядом с Windows используйте ручную разметку и не форматируйте существующий EFI-раздел.

После установки временная учётная запись, автологин live-системы и временное правило sudo удаляются.
Calamares предлагает создать обычного пользователя и задать пароли.

Перед установкой рядом с Windows сделайте резервную копию, сохраните ключ BitLocker при включённом шифровании и проверьте, что EFI-раздел Windows сохранён.

## Сборка

### GitHub Actions

Workflow запускается вручную (Actions → Build NovaOS Gaming ISO → Run workflow) или при изменениях файлов сборки в main.
Артефакт novaos-gaming-iso содержит ISO и SHA256SUMS; GitHub хранит его 7 дней.

### Локально

На актуальной Arch Linux системе с archiso:

```bash
sudo pacman -Syu --needed archiso
bash scripts/ci-build-iso.sh
```

Скрипт копирует официальный профиль Archiso releng, накладывает файлы из overlay/, добавляет пакеты из packages.extra и запускает mkarchiso.

Сборка требует привилегированного контейнера. Если GitHub-hosted runner ограничит mount/namespace, используйте Arch Linux VPS или self-hosted runner.
Результат сборки следует проверить в виртуальной машине и на целевом ноутбуке перед установкой.
