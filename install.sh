#!/bin/sh
#==============================================================================
#  install.sh — установка motd.sh одной командой:
#    curl -fsSL https://raw.githubusercontent.com/WhiteK0T/motd/main/install.sh | sudo sh
#
#  Debian/Ubuntu (есть /etc/update-motd.d) → /etc/update-motd.d/99-motd
#  Остальные дистрибутивы → /usr/local/bin/motd + /etc/profile.d/zz-motd.sh
#
#  Автор:  WhiteK0T
#  GitHub: https://github.com/WhiteK0T/motd
#==============================================================================

# -e: прервать скрипт при первой же ошибке любой команды (curl получил 404 и т.п.)
# -u: считать ошибкой обращение к незаданной переменной (защита от опечаток)
set -eu

# Откуда качать motd.sh. Можно подменить переменной MOTD_URL (например, ветку/тег).
URL="${MOTD_URL:-https://raw.githubusercontent.com/WhiteK0T/motd/main/motd.sh}"
# Каталог-«корень» для установки. Пустой = настоящая система (/).
# Для проверки без root: DESTDIR=/tmp/test sh install.sh
DESTDIR="${DESTDIR:-}"

# Вывести сообщение об ошибке в stderr и завершить скрипт с кодом 1.
die() { echo "install.sh: $*" >&2; exit 1; }

# В систему ставить можно только от root (id -u = 0). В DESTDIR — без root.
[ -n "$DESTDIR" ] || [ "$(id -u)" -eq 0 ] || die "нужны права root: ... | sudo sh"

# Временный файл для скачивания. trap удалит его при ЛЮБОМ выходе из скрипта:
# и при успехе, и после die, и при прерывании из-за set -e — мусор не остаётся.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# Скачиваем тем, что есть в системе: сначала curl, иначе wget (есть в busybox).
#   curl -f: при ошибке HTTP (404 и т.п.) вернуть ошибку, а не сохранить страницу
#   curl -sS: без прогресс-бара, но ошибки показывать;  -L: следовать редиректам
if   command -v curl >/dev/null 2>&1; then curl -fsSL "$URL" -o "$tmp"
elif command -v wget >/dev/null 2>&1; then wget -qO "$tmp" "$URL"
else die "нужен curl или wget"; fi

# Защита от мусора вместо скрипта (HTML-страница, обрыв загрузки):
# первая строка обязана быть shebang'ом #!/bin/sh.
head -n1 "$tmp" | grep -q '^#!/bin/sh' || die "скачан не тот файл: $URL"

if [ -d "$DESTDIR/etc/update-motd.d" ]; then
  # Debian/Ubuntu: run-parts при входе запускает всё из update-motd.d.
  # Имя без расширения (99-motd), иначе run-parts файл пропустит;
  # 99 — чтобы баннер шёл последним, после стандартных сообщений.
  install -m 755 "$tmp" "$DESTDIR/etc/update-motd.d/99-motd"
  echo "Установлено: /etc/update-motd.d/99-motd"
else
  # Остальные дистрибутивы: кладём скрипт как команду motd
  # и вызываем его из profile.d (его читает /etc/profile при входе).
  mkdir -p "$DESTDIR/usr/local/bin" "$DESTDIR/etc/profile.d"
  install -m 755 "$tmp" "$DESTDIR/usr/local/bin/motd"
  # Проверка $- (флаги оболочки, i = интерактивная): показывать баннер только
  # при входе в терминал, а не в scp/rsync/ssh host cmd/bash -lc.
  # $PS1 для этого ненадёжен: его могут экспортировать в окружение.
  # zz- — чтобы шёл последним.
  # shellcheck disable=SC2016  # $- раскрывается при входе, а не здесь
  echo 'case $- in *i*) /usr/local/bin/motd ;; esac' > "$DESTDIR/etc/profile.d/zz-motd.sh"
  # Файлы profile.d подключаются через «.», исполняемыми их делать не нужно.
  chmod 644 "$DESTDIR/etc/profile.d/zz-motd.sh"
  echo "Установлено: /usr/local/bin/motd (запуск из /etc/profile.d/zz-motd.sh)"
fi
