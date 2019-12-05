#!/bin/bash -x

yum -y install sshpass
echo "===== Enabling IP forwarding ====="
if ! grep -q 'net.ipv4.ip_forward=1' /usr/lib/sysctl.d/00-system.conf; then
  echo "net.ipv4.ip_forward=1" >> /usr/lib/sysctl.d/00-system.conf
  systemctl restart network
  sleep 5
fi

# Update pushgateway target IP
sed -i "/9091/ s/10.70.71.164/$(echo $openStackIp)/" ${WORKSPACE}/prometheus/config/prometheus.yml

echo "===== Start prometheus docker ====="
sudo docker stop prometheus ; sudo docker rm prometheus
sudo docker pull prom/prometheus
docker run -d -it --name prometheus -p 9090:9090 \
-v ${WORKSPACE}/prometheus/config:/prometheus/config prom/prometheus \
--config.file=/prometheus/config/prometheus.yml \
--web.enable-lifecycle \
--web.enable-admin-api

docker_status=$(sudo docker inspect prometheus | grep Status | awk -F'"' '{print $4}')
if [ ${docker_status} == running ]; then
    echo "Prometheus docker starts SUCCESS."
else
    echo "Prometheus docker starts FAILED, Job ABORTED!!!"
    exit 1
fi

echo "===== Open firewll to port 9090 ====="
iptables -I INPUT -p tcp --dport 9090 -m state --state NEW -j ACCEPT

echo "===== Configure ssh_config to not prompt message ====="
if ! /etc/ssh/ssh_config | grep "StrictHostKeyChecking" > /dev/null
then
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
else
  sed -i '/StrictHostKeyChecking/s/^#//; /StrictHostKeyChecking/s/ask/no/' /etc/ssh/ssh_config
fi
sed -i "/#UseDNS/ s/^#//; /UseDNS/ s/yes/no/" /etc/ssh/sshd_config
 
set -e

echo "===== Copy id_rsa.pub to controller $openStackIp ====="
sshpass -p $passWord ssh-copy-id -i /root/.ssh/id_rsa.pub -f $userName@$openStackIp 2>/dev/null

echo "===== Copy scripts to controller $openStackIp ====="
ssh $userName@$openStackIp "mkdir -p ~/prometheus/"
scp -r ./prometheus/scripts/ $userName@$openStackIp:~/prometheus/
scp ./prometheus/pushgateway-1031.tar $userName@$openStackIp:~/prometheus/

echo "===== Start pushgateway docker on controller $openStackIp ====="
ssh $userName@$openStackIp "bash ~/prometheus/scripts/start_pushgateway.sh"


echo "===== Start monitoring scripts in all computes ====="
ssh $userName@$openStackIp "bash ~/prometheus/scripts/start_monitoring.sh"
