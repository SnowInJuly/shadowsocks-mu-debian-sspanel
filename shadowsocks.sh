#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

clear
echo
echo "#############################################################"
echo "# One click Install Shadowsocks-Python Manyusers Version    #"
echo "# Author: JulySnow <603723963@qq.com>                       #"
echo "# Thanks: @zd423 <http://zdfans.com>                        #"
echo "#############################################################"
echo

    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
	
apt-get -y update
apt-get -y upgrade
apt-get -y install python-pip m2crypto git vim
apt-get -y install build-essential
cd /root
git clone -b stable https://github.com/jedisct1/libsodium
cd /root/libsodium
./configure
make
make install
ldconfig

cd /root
pip install cymysql
git clone -b manyuser https://github.com/breakwa11/shadowsocks.git
apt-get -y install python-pip python-m2crypto supervisor
sed -i "s/aes-256-cfb/rc4-md5/g" /root/shadowsocks/config.json
mkdir -p /etc/supervisor/conf.d/
cat >>/etc/supervisor/conf.d/shadowsocks.conf<< EOF
[program:shadowsocks]
command=python /root/shadowsocks/server.py
directory=/root/shadowsocks/
autostart=true
autorestart=true
user=root
EOF

cat >>/etc/supervisor/conf.d/ssshell.conf<< EOF
[program:ssshell]
command=java -jar ssshell.jar
directory=/root/ssshell
autostart=true
autorestart=true
user=root
EOF

apt-get -y install libpcap*
cd /lib64
wget https://github.com/glzjin/ssshell-jar/raw/master/libjnetpcap.so
wget https://github.com/glzjin/ssshell-jar/raw/master/libjnetpcap-pcap100.so
mkdir /root/ssshell
cd /root/ssshell
wget https://github.com/glzjin/ssshell-jar/raw/master/ssshell.jar -O /root/ssshell/ssshell.jar 
wget https://github.com/glzjin/ssshell-jar/raw/master/ssshell.conf -O /root/ssshell/ssshell.conf
pip install speedtest-cli
chmod 600 /root/ssshell/ssshell.conf

echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" >>/etc/apt/sources.list
echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" >>/etc/apt/sources.list
apt-get -y install sudo
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
sudo apt-get update
sudo apt-get install oracle-java8-installer

cat >>/etc/security/limits.conf<< EOF
* soft nofile  512000
* hard nofile 1024000
* soft nproc 512000
* hard nproc 512000
EOF

cat >>/etc/sysctl.conf<<EOF
fs.file-max = 1024000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = hybla
EOF


sed -i "s/exit 0/ulimit -n 512000/g" /etc/rc.local
cat >>/etc/rc.local<<EOF
supervisorctl restart all
exit 0
EOF

echo "ulimit -n 512000" >>/etc/default/supervisor
echo "ulimit -n 512000" >>/etc/profile
source /etc/default/supervisor
source /etc/profile
sysctl -p
ulimit -n 51200

host="127.0.0.1"
read -p "输入MySQL,IP地址或者域名: " host
sed -i "s/MYSQL_HOST = '127.0.0.1'/MYSQL_HOST = '${host}'/g" /root/shadowsocks/apiconfig.py

username="root"
read -p "输入MySQL,用户名: " username
sed -i "s/MYSQL_USER = 'ss'/MYSQL_USER = '${username}'/g" /root/shadowsocks/apiconfig.py

password="root"
read -p "输入MySQL,登录密码: " password
sed -i "s/MYSQL_PASS = 'ss'/MYSQL_PASS = '${password}'/g" /root/shadowsocks/apiconfig.py

db="shadowsocks"
read -p "输入MySQL,数据库名: " db
sed -i "s/MYSQL_DB = 'shadowsocks'/MYSQL_DB = '${db}'/g" /root/shadowsocks/apiconfig.py

ip="127.0.0.1"
read -p "本机外网IP: " ip

ip="3"

nodeid=1
read -p "请输入此节点在面板中的ID号: " nodeid
version=3
nic=eth0

sed -i  "s/addresshere/${host}/" /root/ssshell/ssshell.conf 
sed -i "s/addressnamehere/${db}/" /root/ssshell/ssshell.conf 
sed -i "s/addressusernamehere/${username}/" /root/ssshell/ssshell.conf 
sed -i "s/addressuserpassword/${password}/" /root/ssshell/ssshell.conf 
sed -i "s/iphere/${ip}/" /root/ssshell/ssshell.conf 
sed -i "s/nodeidhere/${nodeid}/" /root/ssshell/ssshell.conf 
sed -i "s/versionhere/${version}/" /root/ssshell/ssshell.conf 
sed -i "s/nichere/${nic}/" /root/ssshell/ssshell.conf 

supervisorctl reload
supervisorctl restart all
ulimit -n 51200

echo "恭喜您!Shadowsocks Python多用户版安装并与前段SS-Panel对接完成!"
echo "此脚本仅支持v3前段修改版! 其他版本勿用!"
echo "查看日志:supervisorctl tail -f shadowsocks stderr"
