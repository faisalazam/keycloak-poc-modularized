#!/bin/sh
# wait-for-it.sh

host="$1"
port="$2"
timeout="${3:-30}"

echo "Waiting for $host:$port to be available..."

start_time=$(date +%s)
while ! nc -z "$host" "$port"; do
  now=$(date +%s)
  elapsed=$((now - start_time))
  if [ "$elapsed" -ge "$timeout" ]; then
    echo "$host:$port did not become available in $timeout seconds"
    exit 1
  fi
  sleep 1
done

echo "$host:$port is available"
exec "${@:4}"
