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

trap cleanup SIGINT SIGTERM EXIT

# spawn applications, function 2
spawn_apps(){
}

# collect process metrics, function 3
collect_process_metrics(){
}

# collect system metrics
collect_systm_metric(){
}



