#!/bin/bash
URL="http://wordpress-alb-788077186.ap-south-1.elb.amazonaws.com"

# Traffic profile
DURATION_SEC=180
CONCURRENCY=40
SLOW_RATIO=20         # % of requests that are intentionally slow
ERROR_RATIO=10        # % of requests sent to error paths (mostly 404s)
POST_RATIO=10         # % of requests that are POSTs

PAGES=(
  "/"
  "/wp-login.php"
  "/wp-json/"
  "/?s=cloudwatch"
  "/wp-admin/admin-ajax.php?action=heartbeat"
)

ERROR_PATHS=(
  "/wp-content/plugins/broken-plugin/error.php"
  "/this-path-should-404"
  "/wp-json/nonexistent"
)

echo "Starting mixed traffic simulation on $URL"
echo "Duration: ${DURATION_SEC}s | Concurrency: ${CONCURRENCY}"

start_time=$(date +%s)
end_time=$((start_time + DURATION_SEC))

rand() {
  od -An -N2 -tu2 < /dev/urandom | tr -d ' '
}

pick_random() {
  local -n arr=$1
  local idx=$(( $(rand) % ${#arr[@]} ))
  echo "${arr[$idx]}"
}

make_request() {
  local path="$1"
  local method="$2"
  local slow="$3"

  if [[ "$slow" == "true" ]]; then
    curl -s -o /dev/null -w "%{http_code} %{time_total}\n" \
      --max-time 20 \
      "$URL$path"
  elif [[ "$method" == "POST" ]]; then
    curl -s -o /dev/null -w "%{http_code} %{time_total}\n" \
      -X POST -d "q=test&ts=$(date +%s)" \
      "$URL$path"
  else
    curl -s -o /dev/null -w "%{http_code} %{time_total}\n" \
      "$URL$path"
  fi
}

worker() {
  while [[ $(date +%s) -lt $end_time ]]; do
    local r=$(( $(rand) % 100 ))
    local slow="false"
    local method="GET"
    local path="/"

    if [[ $r -lt $ERROR_RATIO ]]; then
      path=$(pick_random ERROR_PATHS)
    else
      path=$(pick_random PAGES)
    fi

    if [[ $r -ge $ERROR_RATIO && $r -lt $((ERROR_RATIO + POST_RATIO)) ]]; then
      method="POST"
      path="/wp-admin/admin-ajax.php?action=heartbeat"
    fi

    if [[ $r -ge $((100 - SLOW_RATIO)) ]]; then
      slow="true"
    fi

    make_request "$path" "$method" "$slow" >/dev/null &
    sleep 0.1
  done
}

for i in $(seq 1 $CONCURRENCY); do
  worker &
done

wait

echo "Simulation complete. Check CloudWatch in 2-5 minutes."
echo "Note: 5XX errors are not guaranteed unless the app returns 5XX."
