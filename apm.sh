#!/bin/bash

# config & global variables
IP_ADDR="192.168.206.116"
APM_PIDS=()
START_TIME=$SECONDS

rm -f system_metrics.csv

# cleanup, function 1
cleanup() {
  echo -e "\n Signal caught! Terminating APM applications and cleaning up . . ."

  for pid in "${APM_PIDS[@]}";
    do
      if kill -0 "$pid" 2>/dev/null; 
    then
      kill "$pid" 2>/dev/null
    fi
  done

  pkill -P $$ 2>/dev/null

  echo "Cleanup complete. Exiting . . ."
  exit 0
}

# guarantees cleanup runs automatically no matter how script ends
trap cleanup SIGINT SIGTERM EXIT

# spawn applications, function 2
spawn_apps(){
  echo "Spawning APM applications 1-6!"
  
  for i in {1..6};
    do
      if [ -x "./project1_executables/APM$i" ]; then
      ./project1_executables/APM$i "$IP_ADDR" &
      APM_PIDS+=($!)

      echo "  Started APM$i with PID ${APM_PIDS[-1]}"

    else
      echo "  Warning: ./project1_executables/APM$i not found or executable!"
    fi
  done
}

# collect process metrics, function 3
collect_process_metrics(){
  local elapsed=$1

  for i in {1..6};
    do 
    local pid="${APM_PIDS[$((i-1))]}"
    local outfile="APM${i}_metrics.csv"

    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      local metrics
      metrics=$(ps -p "$pid" -o %cpu,%mem --no-headers 2>/dev/null)

      read -r cpu mem <<< "$metrics"

      if [ -n "$cpu" ] && [ -n "$mem" ]; then
        echo "${elapsed},${cpu},${mem}" >> "$outfile"
      fi
    fi
  done
}

# Convert to kB/s
to_kbps(){
	local val=$1
	case "$val" in 
		*K) echo "${val%K}" ;;
		*M) echo "${val%M}" | awk '{printf "%.2f", $1 * 1024}' ;; #MB -> kB
		*) echo "$val" | awk '{printf "%.2f", $1 / 1024}' ;; #bytes -> kB
	esac
}

# collect system metrics
collect_system_metrics(){
  local elapsed=$1
  local line rx tx writes avail
  
  # network RX and TX from daemon
  line=$(ifstat ens192 2>/dev/null | grep ens192)
  rx=$(to_kbps "$(echo "$line" | awk '{print $7}')")
  tx=$(to_kbps "$(echo "$line" | awk '{print $9}')")
  
  # disk writes kbs to sda
  writes=$(iostat -d -k sda 1 2| grep sda | tail -n 1 | awk '{print $4}')
  
  # available space 
  avail=$(df -m / | tail -n 1 | awk '{print $4}')
  
  echo "${elapsed},${rx},${tx},${writes},${avail}" >> system_metrics.csv
  
}

spawn_apps

ifstat -d 1 -t 1

echo "  Starting data collection every 5 seconds, press CTRL+C to stop."

while true; do
  CURRENT_ELAPSED=$(($SECONDS - $START_TIME))

  collect_process_metrics "$CURRENT_ELAPSED"

  collect_system_metrics "$CURRENT_ELAPSED"

  sleep 5


