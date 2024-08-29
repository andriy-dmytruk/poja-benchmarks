#!/usr/bin/bash

systemd-socket-activate --inetd -a -l /tmp/http-poja.sock $(pwd)/demo-poja/target/demo-poja &
PID=$!

total=0
for i in {1..100}; do
  result=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}" --unix-socket /tmp/http-poja.sock http://localhost/)
  if [[ ! $result =~ 200\|([0-9.]+) ]]; then
    echo "Non-200 response"
    kill $PID && wait $PID
    exit
  fi
  request_time=${BASH_REMATCH[1]}
  total=$(echo "$total + $request_time" | bc -l)
done

kill $PID && wait $PID

average=$(echo "${total} / 100" | bc -l)
echo "Average over 100: ${average}s"
