#!/bin/bash
# $1 = zerossl email address
# $2 = CF email
# $3 = CF Global Token
# $4 = TDL
# $5 = ssh git location of your healthcheck script
# $6 = Node Name

zerosslemail="${1}"
cfemail="${2}"
cfapi="${3}"
domain="${4}"
health="${5}"
node="${6}"

apt install curl git -y

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
setupdocker () {
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    wait
    curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
}

setupdockercompose () {
    echo "created and placed the docker-compose.yml to /opt/docker"
    mkdir -p /opt/docker
    cd /opt/docker
    wget -q -O docker-compose.yml https://gitlab.zenterprise.org/hthighway/cdn-create-a-node/-/raw/main/docker-compose.yml
}

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

setuptraefikfolder () {
    echo "Copied the dynamic.yml to /opt/traefik/dynamic_configs"
    mkdir -p /opt/traefik/dynamic_configs
    cd /opt/traefik/dynamic_configs
    wget -q -O dynamic.yml https://gitlab.zenterprise.org/hthighway/cdn-create-a-node/-/raw/main/dynamic.yml
}

setupmainyml () {
    echo "Copied the SSH git repo location for your main.yml to /opt/traefik/dynamic_configs"
    read -r traefikconfig_git
    mkdir -p /opt/traefik
    cd /opt/traefik
    git clone "$traefikconfig_git" dynamic_configs
    FILE=/opt/traefik/dynamic_configs/main.yml
    if [ -f "$FILE" ]; then
        fcheck=0
    else 
        echo "$FILE does not exist, please make sure you provided a correct git ssh url and you type YES to accept the clone"
        fcheck=1
        rm -rf /opt/traefik/dynamic_configs
    fi
}

setupcron () {
    crontab -l > /tmp/mycron
    echo '*/5 * * * * cd /opt/traefik/dynamic_configs &&  git pull >/dev/null 2>&1' >> /tmp/mycron
    crontab /tmp/mycron
    rm /tmp/mycron
}

setupzerossl ()
{
    #  setup zeroSLL eab credetials 
    #  define CF email and global token
    #  set TDL
    #  all in  /opt/docker/.env
    mkdir -p /opt/docker
    tokens=$(curl -Ss "https://api.zerossl.com/acme/eab-credentials-email" --data "email=$zerosslemail")
    kid=$(echo "$tokens}" | grep -o 'eab_kid.*' | cut -f2- -d:)
    kid=${kid%,*}
    key=$(echo "${tokens##*:}")
    key=${key::-1}
    #remove quotes
    kid="${kid%\"}"
    kid="${kid#\"}"
    key="${key%\"}"
    key="${key#\"}"

    echo "CLOUDFLARE_EMAIL=$cfemail
    CLOUDFLARE_API_KEY=$cfapi
    TLD=$domain
    zerossl_email=$zerosslemail
    zerossl_kid=${kid}
    zerossl_key=${key}" > /opt/docker/.env
}

healthcheck () {
    apt install run-one
    echo "Copy the SSH git repo location for your HealthCheck file"
    mkdir -p /opt/scripts
    cd /opt/scripts
    git clone "$health" health

    crontab -l > /tmp/mycron
    echo '*/5 * * * * cd /opt/scripts/health &&  git pull >/dev/null 2>&1' >> /tmp/mycron
    crontab /tmp/mycron
    rm /tmp/mycron

    crontab -l > /tmp/mycron
    echo '*/1 * * * * run-one /bin/bash /opt/scripts/health/healthcheck.sh '"$node"' '"$domain"' > /dev/null 2>&1' >> /tmp/mycron
    crontab /tmp/mycron
    rm /tmp/mycron
}

setupkernel
setupsshkey
setupsysctl
setupdocker
setupdockercompose
setupmainyml
if [ ${fcheck} -eq 0 ]; then 
    :
else
    setupmainyml  
fi
setuptraefikfolder
setupcron
setupzerossl

if [ -z "$health" ]; then
    :
else
    healthcheck
fi



echo "=========================================="
echo "=========================================="
echo "=========================================="
echo "=========================================="
echo "."
echo "."
echo "installation is now complete"
echo "."
echo "the next step that occurs will be to reboot the node to use the newly installe kernel"
echo "after reboot go to /opt/docker"
echo "and start docker-compose with 'docker-compose up -d'"
echo "."
echo "."
echo "=========================================="
echo "=========================================="
echo "=========================================="
read -p "Press enter to reboot"
reboot
