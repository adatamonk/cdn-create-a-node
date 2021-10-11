#!/bin/bash
# $1 = zerossl email address
# $2 = CF email
# $3 = CF Global Token
# $4 = TDL
# 
#
setupsshkey () {
hostname=$(uname -n) 
ssh-keygen -o -a 100 -t ed25519 -f /root/.ssh/id_ed25519 -C "$hostname" 
echo "We now need to send your ssh key that was just generated to we can talk to your repositories on gitlab Enter the following line into your gitlab auth ssh keys at https://gitlab.zenterprise.org/-/profile/keys" 
cat /root/.ssh/id_ed25519.pub
read -p "Press enter to continue"
}



## Kernel Things 
setupkernel () {
apt update -y
apt upgrade -y 
wget -O /usr/local/bin/ubuntu-mainline-kernel.sh https://raw.githubusercontent.com/pimlie/ubuntu-mainline-kernel.sh/master/ubuntu-mainline-kernel.sh 
chmod +x /usr/local/bin/ubuntu-mainline-kernel.sh 
/usr/local/bin/ubuntu-mainline-kernel.sh -i 5.11.11 
wait
}




#  install docker-ce
#  https://github.com/hthighwaymonk/docker-install
#
setupdocker () {
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
wait
}
#
#

#
# set sysctl
setupsysctl () {
echo "net.ipv4.tcp_window_scaling=1
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 134217728
net.ipv4.tcp_wmem=4096 65536 134217728
net.core.netdev_max_backlog=300000
net.ipv4.tcp_moderate_rcvbuf =1
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_mtu_probing=1
fs.file-max=1048576
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=10
net.core.somaxconn=1024
net.ipv4.tcp_max_syn_backlog=30000
net.ipv4.tcp_max_tw_buckets=2000000
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_adv_win_scale=2
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.core.default_qdisc=fq
fs.inotify.max_user_watches=524000
net.core.netdev_budget=50000
net.core.netdev_budget_usecs=5000" > /etc/sysctl.conf
/sbin/sysctl -p
}
#
#

setupdockercompose () {
    echo "Copy the docker-compose.yml to /opt/docker"
    mkdir -p /opt/docker
    cd /opt/docker
    wget -q -O docker-compose.yml https://gitlab.zenterprise.org/hthighway/cdn-create-a-node/-/raw/main/docker-compose.yml
}

setuptraefikfolder () {
    echo "Copy the dynamic.yml to /opt/traefik"
    mkdir -p /opt/traefik
    cd /opt/traefik
    wget -q -O dynamic.yml https://gitlab.zenterprise.org/hthighway/cdn-create-a-node/-/raw/main/dynamic.yml
}


setupmainyml () {
    echo "Copy the SSH git repo location for your traefik configuration files"
    read -r traefikconfig_git
    mkdir -p /opt/scripts
    cd /opt/scripts
    git clone "$traefikconfig_git" traefik
}


setupkernel
setupsshkey
setupsysctl
setupdocker
setupdockercompose
setuptraefikfolder



#  setup zeroSLL eab credetials 
#  define CF email and global token
#  set TDL
#  all in  /opt/docker/.env
mkdir -p /opt/docker
tokens=$(curl -Ss "https://api.zerossl.com/acme/eab-credentials-email" --data "email=$1")
kid=$(echo "$tokens}" | grep -o 'eab_kid.*' | cut -f2- -d:)
kid=${kid%,*}
key=$(echo "${tokens##*:}")
key=${key::-1}
#remove quotes
kid="${kid%\"}"
kid="${kid#\"}"
key="${key%\"}"
key="${key#\"}"

echo "CLOUDFLARE_EMAIL=$2
CLOUDFLARE_API_KEY=$3
TDL=$4
zerossl_email=$1
zerossl_kid=${kid}
zerosssl_key=${key}" > /opt/docker/.env

