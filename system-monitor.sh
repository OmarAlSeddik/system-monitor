GUI_menu() {
    zenity --list --title="Task Manager\
        --text="Choose an option:" \
        --column="Option" --column="Description" \
        1 "CPU Usage" \
        2 "GPU Usage" \
        3 "Disk Usage" \
        4 "Memory Usage" \
        5 "Network Stats" \
        6 "Exit"
}

while true; do
    option=$(GUI_menu)

    case $option in
        1) cpu_usage ;;
        2) gpu ;;
        3) disk_usage ;;
        4) memory_usage ;;
        5) network_stat ;;
        6) system_load ;; 
        *) zenity --error --title="Invalid Option" --text="Please select a valid option." ;;
    esac
done

get_cpu_usage() {
  if command -v mpstat &>/dev/null; then
    mpstat 1 1 | awk '/Average:/ {printf "%.1f", 100 - $NF}'
  else
    top -bn1 | awk -F'id,' '/Cpu/ {split($1, a, " "); print 100 - a[NF]}' || echo "N/A"
  fi
}

get_cpu_temp() {
  sensors 2>/dev/null | awk '/Core 0|Tctl/ {print $2}' | head -n1 | tr -d '+°C' || echo "N/A"
}

get_gpu_stats() {
  if command -v nvidia-smi &>/dev/null; then
    GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1)
    GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -n1)
  elif command -v radeontop &>/dev/null; then
    GPU_UTIL=$(radeontop -d - | grep -m 1 -oP "gpu \K[0-9]+" || echo "N/A")
    GPU_TEMP=$(sensors 2>/dev/null | awk '/edge/ {print $2}' | tr -d '+°C' | head -n1 || echo "N/A")
  else
    GPU_UTIL="N/A"
    GPU_TEMP="N/A"
  fi
  echo "$GPU_UTIL,$GPU_TEMP"
}

get_disk_usage() {
  disk=$(lsblk -ndo NAME,TYPE | awk '$2 == "disk" {print $1; exit}')
  if [ -z "$disk" ]; then
    echo "No disk found"
    return
  fi
  mapfile -t partitions < <(lsblk -nlo NAME,TYPE,MOUNTPOINT "/dev/$disk" | awk '$2 == "part" {print $1 "," $3}')
  json_output='{'
  json_output+="\"disk\": \"/dev/$disk\", \"partitions\": ["
  for partition in "${partitions[@]}"; do
    IFS=',' read -r part_name mountpoint <<< "$partition"
    json_output+="{\"name\": \"/dev/$part_name\", "
    if [ -n "$mountpoint" ]; then
      usage=$(df -h "$mountpoint" 2>/dev/null | awk 'NR==2 {print $5}')
      json_output+="\"mountpoint\": \"$mountpoint\", \"usage\": \"$usage\"}"
    else
      json_output+="\"mountpoint\": null, \"usage\": null}"
    fi
    if [ "$partition" != "${partitions[-1]}" ]; then
      json_output+=", "
    fi
  done
  json_output+="]}"
  echo "$json_output"
}

get_memory_usage() {
  free -m | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}'
}

get_network_stats() {
  if command -v ifstat &>/dev/null; then
    ifstat 1 1 2>/dev/null | tail -n 1 | awk '{print "Received Bytes: " $1 ", Transmitted Bytes: " $2}'
  elif command -v sar &>/dev/null; then
    sar -n DEV 1 1 2>/dev/null | awk '/Average:.*eth0/ {print "Received Bytes: " $5 ", Transmitted Bytes: " $6}'
  elif [[ -r /proc/net/dev ]]; then
    awk 'NR>2 {rx+=$2; tx+=$10} END {print "Received Bytes: " rx ", Transmitted Bytes: " tx}' /proc/net/dev
  else
    echo "N/A - No compatible tool found for network stats."
  fi
}

check_system() {
  CPU=$(get_cpu_usage)
  CPU_TEMP=$(get_cpu_temp)
  GPU_STATS=$(get_gpu_stats)
  GPU_UTIL=$(echo "$GPU_STATS" | cut -d',' -f1)
  GPU_TEMP=$(echo "$GPU_STATS" | cut -d',' -f2)
  DISK=$(get_disk_usage)
  MEMORY=$(get_memory_usage)
  LOAD=$(get_load_average)
  NETWORK=$(get_network_stats)

  cat <<EOF
{
  "cpu_usage": "$CPU",
  "cpu_temp": "$CPU_TEMP",
  "gpu_utilization": "$GPU_UTIL",
  "gpu_temp": "$GPU_TEMP",
  "disk_usage": $DISK,
  "memory": "$MEMORY",
  "load_avg": "$LOAD",
  "network_stats": "$NETWORK"
}
EOF
}

main() {
  check_system
}

main
