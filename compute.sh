#!/bin/bash

sudo apt-get update
sudo apt-get install -y git python-pip vim
sudo apt-get upgrade -y python


touch host
sudo sed -e "s/[        ]*127.0.0.1[    ]*localhost[    ]*$/127.0.0.1 localhost $HOSTNAME/" /etc/hosts > host
sudo cp -f host /etc/hosts
sudo su -c "useradd stack -s /bin/bash -m -g cc -G cc"
sudo sed -i '$a stack ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
chown stack:cc /home/stack
cd /home/stack



git clone https://github.com/openstack-dev/devstack.git -b stable/liberty
sudo chown -R stack:cc /home/stack/*

cd devstack

SERVICE_HOST=$master_ip$
HOST_IP=$(/sbin/ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')

#VAR=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

#printf '\nHOST_IP=%s'$VAR'\n' >> local.conf



touch interface
cat <<EOF | cat > interface
auto eth0
iface eth0 inet static
        address $HOST_IP 
        netmask 255.255.254.0
        broadcast 10.40.1.255
        gateway 10.40.1.254
EOF

#sudo cp -f interface /etc/network/interfaces
#sudo ifdown eth0
#sudo ifup eth0

cat <<EOF | cat > local.conf
[[local|localrc]]
#credential
SERVICE_TOKEN=secret
ADMIN_PASSWORD=secret
MYSQL_PASSWORD=secret
RABBIT_PASSWORD=secret
SERVICE_PASSWORD=secret
#network
FLAT_INTERFACE=eth0
FIXED_RANGE=192.168.1.0/24
NETWORK_GATEWAY=192.168.1.1
FIXED_NETWORK_SIZE=4096
HOST_IP=$HOST_IP
PUBLIC_NETWORK_GATEWAY=10.40.1.254
#multi_host
MULTI_HOST=1
SERVICE_HOST=$SERVICE_HOST
DATABASE_TYPE=mysql
MYSQL_HOST=$SERVICE_HOST
RABBIT_HOST=$SERVICE_HOST
GLANCE_HOSTPORT=$SERVICE_HOST:9292
Q_HOST=$SERVICE_HOST
KEYSTONE_AUTH_HOST=$SERVICE_HOST
KEYSTONE_SERVICE_HOST=$SERVICE_HOST
CINDER_SERVICE_HOST=$SERVICE_HOST
NOVA_VNC_ENABLED=True
NOVNCPROXY_URL="http://$SERVICE_HOST:6080/vnc_auto.html"
VNCSERVER_LISTEN=$HOST_IP
VNCSERVER_PROXYCLIENT_ADDRESS=$HOST_IP
#service
ENABLED_SERVICES=n-cpu,n-api,n-api-meta,neutron,q-agt,q-meta
Q_PLUGIN=ml2
Q_ML2_TENANT_NETWORK_TYPE=vxlan
# Enable Logging
LOGFILE=/opt/stack/logs/stack.sh.log
VERBOSE=True
LOG_COLOR=True
SCREEN_LOGDIR=/opt/stack/logs
EOF

touch sysctl.conf
sudo sed -e "s/as needed.$/as needed.\n net.ipv4.ip_forward=1\n/" /etc/sysctl.conf >  sysctl.conf

sudo sed -e "s/as needed.$/as needed.\n net.ipv4.conf.default.rp.filter=0\n/" sysctl.conf > sysctl.conf

sudo sed -e "s/as needed.$/as needed.\n net.ipv4.conf.all.rp.filter=0\n/" sysctl.conf > sysctl.conf

sudo cp -f sysctl.conf /etc/sysctl.conf

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE




sleep 23m
./stack.sh
