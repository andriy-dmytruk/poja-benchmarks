#!/usr/bin/bash

args="-Dmicronaut.server.netty.listeners.inetd.family=UNIX -Dmicronaut.server.netty.listeners.inetd.server-socket=false -Dmicronaut.server.netty.listeners.inetd.accepted-fd=0 -Dmicronaut.server.netty.listeners.inetd.bind=false"
systemd-socket-activate --inetd -a -l /tmp/http-netty.sock $(pwd)/demo-netty/target/demo-netty $args &
PID=$!

total=0
for i in {1..100}; do
  result=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}" --unix-socket /tmp/http-netty.sock http://localhost/)
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
