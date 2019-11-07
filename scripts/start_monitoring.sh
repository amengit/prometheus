#!/bin/bash -x

userName=cloudadmin
computeL=$(openstack host list | grep compute | cut -d' ' -f2 | sort | uniq)
echo "All computes $computeL"
scriptL=(push_cpu.sh push_io.sh push_memory.sh)
for com in $computeL
do
  echo "Copy scripts to $com and run it"
  ssh $com "rm -rf ./prometheus/;mkdir -p ./prometheus/"
  scp -r ./prometheus/scripts/ $userName@$com:./prometheus/
  for spt in ${scriptL[@]}
  do
    echo "  Run script $spt on $com"
    bash ~/prometheus/scripts/$spt
  done
done
