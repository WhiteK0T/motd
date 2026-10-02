#!/bin/sh
#==============================================================================
#  motd.sh — универсальный MOTD-баннер для Linux (баннер при входе)
#  Хост, IP, ОС, ядро, CPU (ядра/потоки), пользователи, нагрузка, память, аптайм.
#  Кроссдистрибутивный: все данные из /proc + базовые утилиты, чистый POSIX sh
#  (работает под bash/dash/busybox-ash, на Gentoo/Debian/Ubuntu/Arch/Alpine...).
#
#  Автор:  WhiteK0T
#  GitHub: https://github.com/WhiteK0T/motd
#==============================================================================
tcLtG="\033[00;37m"; tcLtGRN="\033[01;32m"; tcLtBL="\033[01;34m"
tcORANGE="\033[38;5;209m"; tcRESET="\033[0m"; tcDkG="\033[01;30m"

# повтор символа N раз (POSIX, корректно с UTF-8)
rep() { _n=$1; _c=$2; _s=''; while [ "$_n" -gt 0 ]; do _s="$_c$_s"; _n=$((_n-1)); done; printf '%s' "$_s"; }

# цветной бар: $1=процент (float/int), $2=ширина. Цвет по порогам.
bar() {
  _p=${1%.*}; [ -z "$_p" ] && _p=0
  _w=${2:-24}
  _f=$(( _p * _w / 100 )); [ "$_f" -gt "$_w" ] && _f=$_w; [ "$_f" -lt 0 ] && _f=0
  _e=$(( _w - _f ))
  if   [ "$_p" -ge 90 ]; then _c="\033[01;31m"
  elif [ "$_p" -ge 70 ]; then _c="\033[01;33m"
  else                        _c="\033[01;32m"; fi
  printf '%b' "${_c}$(rep "$_f" '█')${tcDkG}$(rep "$_e" '░')${tcRESET} ${_c}${_p}%${tcRESET}"
}

HOUR=$(date +%H)
if   [ "$HOUR" -lt 12 ]; then TIME="morning"
elif [ "$HOUR" -lt 17 ]; then TIME="afternoon"
else TIME="evening"; fi

up=$(cut -d. -f1 /proc/uptime)
upDays=$((up/86400)); upHours=$((up/3600%24)); upMins=$((up/60%60))

SYS_LOADS=$(awk '{print $1}' /proc/loadavg)
set -- /proc/[0-9]*; NUM_PROCS=$#                      # процессы напрямую из /proc
MEMORY_USED=$(awk '/^MemTotal:/{t=$2}/^MemAvailable:/{a=$2} END{if(t>0)printf "%.1f",(t-a)/t*100; else print "0.0"}' /proc/meminfo)
SWAP_USED=$(awk '/^SwapTotal:/{t=$2}/^SwapFree:/{f=$2} END{if(t>0)printf "%.1f",(t-f)/t*100; else print "0.0"}' /proc/meminfo)
NUM_USERS=$(who 2>/dev/null | wc -l)
USERS_LIST=$(who 2>/dev/null | awk '{print $1}' | sort -u | paste -sd' ')

IPADDRESS=$(ip -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | paste -sd' ')
[ -z "$IPADDRESS" ] && IPADDRESS=$(hostname -I 2>/dev/null)

HOSTN=$(hostname -f 2>/dev/null); [ -z "$HOSTN" ] && HOSTN=$(hostname 2>/dev/null)
[ -z "$HOSTN" ] && HOSTN=$(cat /etc/hostname 2>/dev/null || uname -n)

OS_REL=$( . /etc/os-release 2>/dev/null; printf '%s' "$PRETTY_NAME" )
[ -z "$OS_REL" ] && OS_REL=$(uname -o 2>/dev/null || echo Linux)
[ -r /etc/gentoo-release ] && OS_REL="$OS_REL [$(cat /etc/gentoo-release)]"
[ -r /etc/debian_version ] && OS_REL="$OS_REL [$(cat /etc/debian_version)]"

THREADS=$(grep -c '^processor' /proc/cpuinfo)
CORES=$(awk -F: '/^physical id/{p=$2}/^core id/{s[p":"$2]=1} END{n=0;for(k in s)n++;print n}' /proc/cpuinfo)
[ "${CORES:-0}" -le 0 ] && CORES=$THREADS

SEP="======================================================================"
printf '%b\n' "${tcLtG}${SEP}"
printf '%b\n' "${tcLtG} Good ${TIME}!                                           ${tcORANGE}by WhiteK0T.${tcRESET}"
printf '%b\n' "${tcLtG}${SEP}"
printf '%b\n' "${tcLtGRN} - Server Date/Time  :${tcLtBL} $(date '+%a %d %b %Y / %X %Z')"
printf '%b\n' "${tcLtGRN} - Hostname          :${tcLtBL} ${HOSTN}"
printf '%b\n' "${tcLtGRN} - IP Address        :${tcLtBL} ${IPADDRESS}"
printf '%b\n' "${tcLtGRN} - OS Release        :${tcLtBL} ${OS_REL}"
printf '%b\n' "${tcLtGRN} - Kernel            :${tcLtBL} $(uname -r)"
printf '%b\n' "${tcLtGRN} - CPU Cores/Threads :${tcLtBL} ${CORES} / ${THREADS}"
printf '%b\n' "${tcLtGRN} - Users             :${tcLtBL} ${NUM_USERS} logged on"
printf '%b\n' "${tcLtGRN} - Logged in         :${tcLtBL} ${USERS_LIST}"
printf '%b\n' "${tcLtGRN} - System load       :${tcLtBL} ${SYS_LOADS} / ${NUM_PROCS} processes"
printf '%b\n' "${tcLtGRN} - Memory used       :${tcLtBL} $(bar "$MEMORY_USED" 24)"
printf '%b\n' "${tcLtGRN} - Swap used         :${tcLtBL} $(bar "$SWAP_USED" 24)"
printf '%b\n' "${tcLtGRN} - Uptime            :${tcLtBL} ${upDays}d ${upHours}h ${upMins}m"
printf '%b\n' "${tcLtG}${SEP}${tcRESET}"
