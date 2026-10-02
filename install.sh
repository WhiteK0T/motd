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
set -eu

URL="${MOTD_URL:-https://raw.githubusercontent.com/WhiteK0T/motd/main/motd.sh}"
DESTDIR="${DESTDIR:-}"                                  # для проверки без root

die() { echo "install.sh: $*" >&2; exit 1; }

[ -n "$DESTDIR" ] || [ "$(id -u)" -eq 0 ] || die "нужны права root: ... | sudo sh"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

if   command -v curl >/dev/null 2>&1; then curl -fsSL "$URL" -o "$tmp"
elif command -v wget >/dev/null 2>&1; then wget -qO "$tmp" "$URL"
else die "нужен curl или wget"; fi

head -n1 "$tmp" | grep -q '^#!/bin/sh' || die "скачан не тот файл: $URL"

if [ -d "$DESTDIR/etc/update-motd.d" ]; then
  install -m 755 "$tmp" "$DESTDIR/etc/update-motd.d/99-motd"
  echo "Установлено: /etc/update-motd.d/99-motd"
else
  mkdir -p "$DESTDIR/usr/local/bin" "$DESTDIR/etc/profile.d"
  install -m 755 "$tmp" "$DESTDIR/usr/local/bin/motd"
  # shellcheck disable=SC2016  # $PS1 раскрывается при входе, а не здесь
  echo '[ -n "$PS1" ] && /usr/local/bin/motd' > "$DESTDIR/etc/profile.d/zz-motd.sh"
  chmod 644 "$DESTDIR/etc/profile.d/zz-motd.sh"
  echo "Установлено: /usr/local/bin/motd (запуск из /etc/profile.d/zz-motd.sh)"
fi
