# CDN Create a Node

create  CDZen Nodes using docker / Traefik / ZeroSSL


## How To Install

```
wget -q -O install.sh https://gitlab.zenterprise.org/hthighway/cdn-create-a-node/-/raw/main/install.sh
bash ./install.sh <zerossl email> <CF email> <CF global api> <TDL> <ssh git repo for healthcheck> <name of node>
```

script will ask you for the git location of your main.yml file

so have that created before running the script

------------------------------------------------------------

if you want to install the health check script you will need to have a fully edited version of it ready in it's own git repo

then  provde it's ssh git and node name for <ssh git repo for healthcheck> <name of node> above

------------------------------------------------------------

Updated kernel

updates sysctl

installs docker-ce using `sh get-docker.sh`

populates a /opt/docker/.env file with - 
-    CF email
-    CF Global API key
-    ZerroSSL email
-    ZeroSLL eab_kid
-    ZeroSSL eab_key
-    ZeroSSl email
-    TDL

populates /opt/docker/docker-compose.yml

populates /opt/traefik/dynamic.yml

grabs your main.yml from your gitlab and symlinks it to /opt/traefik/main.yml

adds a cronb job to keep main.yml updated
