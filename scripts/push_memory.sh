#!/bin/bash
# desc push memory info

total_memory=$(free  |awk '/Mem/{print $2}')
used_memory=$(free  |awk '/Mem/{print $3}')

job_name="custom_memory"
instance_name=$(hostname)

cat <<EOF | curl --data-binary @- http://192.168.54.19:9091/metrics/job/$job_name/instance/$instance_name
#TYPE custom_memory_total  gauge
custom_memory_total $total_memory
#TYPE custom_memory_used  gauge
custom_memory_used $used_memory
EOF

