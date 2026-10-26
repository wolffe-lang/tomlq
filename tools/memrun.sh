#!/bin/bash
# memrun.sh LIMIT_MB SECS CMD... — run CMD; kill it if its RSS passes LIMIT_MB or it runs past SECS.
# Prints one line to stderr: memrun: rc=N maxrss_mb=M secs=S.SS [killed=memory|time]
limit=$1; secs=$2; shift 2
now() { python3 -c 'import time; print(time.time())'; }
start=$(now)
"$@" &
pid=$!
max=0; killed=""; ticks=0
while kill -0 "$pid" 2>/dev/null; do
  rss=$(ps -o rss= -p "$pid" 2>/dev/null | tr -d ' ')
  [ -n "$rss" ] && [ "$rss" -gt "$max" ] && max=$rss
  if [ $((max / 1024)) -gt "$limit" ]; then killed=memory; kill -9 "$pid" 2>/dev/null; break; fi
  if [ $((ticks / 10)) -gt "$secs" ]; then killed=time; kill -9 "$pid" 2>/dev/null; break; fi
  sleep 0.1; ticks=$((ticks + 1))
done
wait "$pid" 2>/dev/null; rc=$?
el=$(python3 -c "print('%.2f' % ($(now) - $start))")
echo "memrun: rc=$rc maxrss_mb=$((max / 1024)) secs=$el${killed:+ killed=$killed}" >&2
[ -n "$killed" ] && exit 124
exit $rc
