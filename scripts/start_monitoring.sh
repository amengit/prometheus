#!/bin/bash -x

userName=cloudadmin
hostName=$(hostname)
pushGWIp=$(cat /etc/hosts | grep $hostName | awk '{print $1}')

computeL=$(openstack host list | grep compute- | cut -d' ' -f2 | sort | uniq)
echo -e "All computes:\n$computeL"
scriptL=(push_cpu.sh push_io.sh push_memory.sh)

# update pushgateway server ip in monitoring scripts
for spt in ${scriptL[@]}
  do
    sed -i "/pushGWIp/ s/http.*/$pushGWIp/" ./prometheus/scripts/$spt
  done

for com in $computeL
do
  echo "Copy scripts to $com and run it"
  ssh -o StrictHostKeyChecking=no $com "rm -rf ./prometheus/;mkdir -p ./prometheus/" >/dev/null 2>&1
  scp -r ./prometheus/scripts/ $userName@$com:./prometheus/ >/dev/null 2>&1
  ssh $com "crontab ~/prometheus/scripts/monitoring.crontab" >/dev/null 2>&1
done
