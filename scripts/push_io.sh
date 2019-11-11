#!/bin/bash
# desc push I/O info

declare -A io_status
iostat_out=io_stat_output.log
iostat_push_file=io_stat_push_data
iostat | grep -A100 "Device:" | grep -v "Device" > $iostat_out
sed -i '/^$/d' $iostat_out
while read line
do
  device=$(echo $line | awk '{print $1}')
  tps=$(echo $line | awk '{print $2}')
  kb_read_per_s=$(echo $line | awk '{print $3}')
  kb_wrtn_per_s=$(echo $line | awk '{print $4}')
  kb_read=$(echo $line | awk '{print $5}')
  kb_wrtn=$(echo $line | awk '{print $6}')
  io_status[$device]=$tps-$kb_read_per_s-$kb_wrtn_per_s-$kb_read-$kb_wrtn
done < $iostat_out

rm -rf $iostat_out

job_name="custom_io"
instance_name=$(hostname)
pushGWIp=http://192.168.54.19
pushGWPort=9091

echo > $iostat_push_file
for dev in ${!io_status[*]}
do
  dev_=$(echo ${dev/-/_})
  echo "# TYPE custom_io_${dev_}_tps gauge" >> $iostat_push_file
  echo custom_io_${dev_}_tps{device=\""${dev}"\"} $(echo ${io_status[$dev]} | awk -F '-' '{print $1}') >> $iostat_push_file
  echo "# TYPE custom_io_${dev_}_kb_read_per_s gauge" >> $iostat_push_file
  echo custom_io_${dev_}_kb_read_per_s{device=\""${dev}"\"} $(echo ${io_status[$dev]} | awk -F '-' '{print $2}') >> $iostat_push_file
  echo "# TYPE custom_io_${dev_}_kb_wrtn_per_s gauge" >> $iostat_push_file
  echo custom_io_${dev_}_kb_wrtn_per_s{device=\""${dev}"\"} $(echo ${io_status[$dev]} | awk -F '-' '{print $3}') >> $iostat_push_file
  echo "# TYPE custom_io_${dev_}_kb_read gauge" >> $iostat_push_file
  echo custom_io_${dev_}_kb_read{device=\""${dev}"\"} $(echo ${io_status[$dev]} | awk -F '-' '{print $4}') >> $iostat_push_file
  echo "# TYPE custom_io_${dev_}_kb_wrtn gauge" >> $iostat_push_file
  echo custom_io_${dev_}_kb_wrtn{device=\""${dev}"\"} $(echo ${io_status[$dev]} | awk -F '-' '{print $5}') >> $iostat_push_file
  echo >> $iostat_push_file
done

cat $iostat_push_file | curl --data-binary @- $pushGWIp:$pushGWPort/metrics/job/$job_name/instance/$instance_name
rm -rf $iostat_push_file

