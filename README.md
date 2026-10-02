# motd

Универсальный цветной MOTD-баннер для Linux, который показывается при входе в систему.

Выводит хост, IP, ОС, ядро, CPU (ядра/потоки), пользователей, нагрузку,
использование памяти и swap (с цветными полосами) и аптайм.

```
======================================================================
 Good evening!                                           by WhiteK0T.
======================================================================
 - Server Date/Time  : Fri 02 Oct 2026 / 22:20:06 MSK
 - Hostname          : host.example.org
 - IP Address        : 192.0.2.10 172.17.0.1
 - OS Release        : Gentoo Linux [Gentoo Base System release 2.18]
 - Kernel            : 7.2.8-gentoo
 - CPU Cores/Threads : 8 / 8
 - Users             : 1 logged on
 - Logged in         : user
 - System load       : 0.00 / 226 processes
 - Memory used       : █░░░░░░░░░░░░░░░░░░░░░░░ 6%
 - Swap used         : ░░░░░░░░░░░░░░░░░░░░░░░░ 0%
 - Uptime            : 7d 0h 53m
======================================================================
```

## Особенности

- **Чистый POSIX `sh`** — работает в `bash`, `dash` и `busybox ash`.
- **Кроссдистрибутивный** — Gentoo, Debian, Ubuntu, Arch, Alpine и другие.
  Данные берутся из `/proc` и базовых утилит, без `lsb_release`, `free` и `ps`.
- **Цветные полосы** для памяти и swap. Цвет зависит от заполнения:
  зелёный — меньше 70%, жёлтый — 70–89%, красный — от 90%.
- **Запасные варианты** для каждого поля: если утилиты нет, используется
  другой источник данных.

## Требования

- Linux с `/proc`.
- `sh`, `awk`, `grep`, `cut`, `sort`, `paste`, `date`, `uname`, `who`.
- Необязательно: `ip` (iproute2) или `hostname` — для IP-адресов и имени хоста.
- Терминал с поддержкой 256 цветов и UTF-8 (для полос `█`/`░`).

## Установка

### Одной командой

```sh
curl -fsSL https://raw.githubusercontent.com/WhiteK0T/motd/main/install.sh | sudo sh
```

или через `wget`:

```sh
wget -qO- https://raw.githubusercontent.com/WhiteK0T/motd/main/install.sh | sudo sh
```

Установщик сам выбирает способ: если есть `/etc/update-motd.d` (Debian/Ubuntu),
скрипт ставится туда как `99-motd`, иначе — в `/usr/local/bin/motd` с запуском
из `/etc/profile.d/zz-motd.sh` (см. ниже).

### Debian / Ubuntu (`update-motd`)

```sh
sudo install -m 755 motd.sh /etc/update-motd.d/99-motd
```

Имя файла в `/etc/update-motd.d/` должно быть без расширения, иначе `run-parts`
его пропустит. Чтобы убрать стандартные сообщения, снимите право на исполнение
с остальных скриптов в этом каталоге.

### Другие дистрибутивы (Gentoo, Arch, Alpine, …)

Установите скрипт как команду и вызывайте его из `/etc/profile.d/`:

```sh
sudo install -m 755 motd.sh /usr/local/bin/motd
echo '[ -n "$PS1" ] && /usr/local/bin/motd' | sudo tee /etc/profile.d/zz-motd.sh
```

Скрипт запускается отдельным процессом, а не через `source`, поэтому его
переменные не попадают в окружение оболочки. Проверка `$PS1` отключает
вывод в неинтерактивных сессиях (`scp`, `rsync`, `ssh host cmd`).

### Вручную

```sh
sh motd.sh
```

## Выводимые поля

| Поле                | Источник                                                       |
|---------------------|----------------------------------------------------------------|
| Server Date/Time    | `date`                                                         |
| Hostname            | `hostname -f` → `hostname` → `/etc/hostname` → `uname -n`      |
| IP Address          | `ip -o addr show scope global` → `hostname -I`                 |
| OS Release          | `/etc/os-release` (+ `/etc/gentoo-release`, `/etc/debian_version`) |
| Kernel              | `uname -r`                                                     |
| CPU Cores/Threads   | `/proc/cpuinfo` (`physical id` + `core id` / `processor`)      |
| Users               | `who` — количество сессий                                      |
| Logged in           | `who` — уникальные имена пользователей                         |
| System load         | `/proc/loadavg` (1 минута) / число каталогов `/proc/[0-9]*`    |
| Memory used         | `/proc/meminfo`: `(MemTotal − MemAvailable) / MemTotal`        |
| Swap used           | `/proc/meminfo`: `(SwapTotal − SwapFree) / SwapTotal`          |
| Uptime              | `/proc/uptime`                                                 |

## Настройка

Цвета задаются переменными в начале `motd.sh` (`tcLtG`, `tcLtGRN`, `tcLtBL`,
`tcORANGE`, `tcDkG`). Ширина полос — второй аргумент функции `bar`
(по умолчанию `24`), пороги цвета — внутри этой функции.

## История версий

См. [CHANGELOG.md](CHANGELOG.md). Первая версия скрипта (`99-motd`, только
для Debian/Ubuntu) удалена из репозитория, но доступна в истории git
(тег `v1.0.0` / коммит `0265edc`).

## Автор

WhiteK0T — <https://github.com/WhiteK0T/motd>
