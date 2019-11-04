#!/bin/bash -x
# desc push cpu info

cpu_idle=$(iostat -c | awk '/    /{print $6}')
cpu_user=$(iostat -c | awk '/    /{print $1}')
cpu_system=$(iostat -c | awk '/    /{print $3}')
cpu_io_wait=$(iostat -c | awk '/    /{print $4}')

job_name="custom_cpu"
instance_name=$(hostname)

cat <<EOF | curl --data-binary @- http://192.168.54.19:9091/metrics/job/$job_name/instance/$instance_name
#TYPE custom_cpu_idle  gauge
custom_cpu_idle $cpu_idle
#TYPE custom_cpu_user  gauge
custom_cpu_user $cpu_user
#TYPE custom_cpu_system  gauge
custom_cpu_system $cpu_system
#TYPE custom_cpu_io_wait  gauge
custom_cpu_io_wait $cpu_io_wait
EOF

