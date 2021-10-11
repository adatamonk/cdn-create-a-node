# CDN Create a Node

create  CDZen Nodes using docker / Traefik / ZeroSSL


## How To Install

```
wget -q -O install.sh https://gitlab.zenterprise.org/hthighway/cdn-create-a-node/-/raw/main/install.sh
bash ./install.sh <zerossl email> <CF email> <CF global api> <TDL> <ssh git repo for healthcheck> <name of node>

examples:  
(no health check installed)
bash ./install.sh emailyouused@zerrssl cfemail@address asdasd876asjhasghd5asdasd fanydomainname 

(with health check installed)
bash ./install.sh emailyouused@zerrssl cfemail@address asdasd876asjhasghd5asdasd fanydomainname ssh://git@gitlab-ssh.zenterprise.org:2222/ you_username/git_forhealthcheck.git UKNODE
```

script will ask you for the git location of your main.yml file

so have that created before running the script

there is a sample file in this repo `main.yml.sample`

------------------------------------------------------------

if you want to install the health check script you will need to have a fully edited version of it ready in it's own git repo

then provde it's ssh git and node name for <ssh git repo for healthcheck> <name of node> above

there is a sample healthcheck in this repo `healthcheck.sh.sample`

------------------------------------------------------------
What Hasppens:

Updated kernel installed

updates sysctl using ZenDC standards

installs docker-ce using `sh get-docker.sh`

installs docker-compose

populates a /opt/docker/.env file with - 
-    CF email
-    CF Global API key
-    ZerroSSL email
-    ZeroSLL eab_kid
-    ZeroSSL eab_key
-    TDL

populates /opt/docker/docker-compose.yml

populates /opt/traefik/dynamic_configs/dynamic.yml

grabs your main.yml from your gitlab and clones it to /opt/traefik/dynamic_configs/main.yml

adds a cronb job to keep main.yml updated

and if you chose, it will install your healthcheck and add a cron job for it
