#!/bin/bash -x

pushgw_image=pushgateway-1031.tar
echo "===== Start pushgateway docker ====="
sudo systemctl restart docker
sudo docker stop pushgateway ; sudo docker rm pushgateway
sudo docker images | grep pushgateway || sudo docker load < prometheus/$pushgw_image
sudo docker run -d -it --name=pushgateway \
-p 9091:9091 \
pushgateway-1031 \
--web.enable-admin-api \
--persistence.file=pushfile.txt \
--persistence.interval=10m

docker_status=$(sudo docker inspect pushgateway | grep Status | awk -F'"' '{print $4}')
if [ ${docker_status} == running ]; then
    echo "Pushgateway docker starts SUCCESS."
else
    echo "Pushgateway docker starts FAILED, Job ABORTED!!!"
    exit 1
fi

echo "===== Open firewll to port 9091 ====="
sudo iptables -I INPUT -p tcp --dport 9091 -m state --state NEW -j ACCEPT
