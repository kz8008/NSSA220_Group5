#!/bin/bash

# config & global variables
IP_ADDR="192.168.206.116"
APM_PIDS=()
START_TIME=$SECONDS

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
  echo 0
}

# guarantees cleanup runs automatically no matter h0w script ends
trap cleanup SIGINT SIGTERM EXIT

# spawn applications, function 2
spawn_apps(){
  echo "Spawning APM applications 1-6!"
  
  for i in {1..6};
    do
      if [ -x "/project1_executables/APM$i" ]; then
      /project1_executables/APM$i "$IP_ADDR" &
      APDM_PIDS+=($!)

      echo "  Started APM$i with PID ${APM_PIDS[-1]}"

    else
      echo "  Warning: /project1_executables/APM$i not found or executable!"
    fi
  done
}

# collect process metrics, function 3
collect_process_metrics(){
  local elapsed=$1

  for i in {1..6};
    do 
    local pid="${APM_PIDS[$9(i-1))]}"
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

# collect system metrics
collect_systm_metric(){
  local elapsed=$1
}





