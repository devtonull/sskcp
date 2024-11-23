#!/bin/bash
###############
# Author: https://github.com/devtonull
# Source: https://github.com/xtaci/kcptun
###############

cd /usr/local/kcptun
get_ip() {
    local IP
    IP=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v '^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\.' | head -n 1)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
    [ -z "${IP}" ] && IP=$(wget -qO- -t1 -T2 ipinfo.io/ip)
    echo "${IP}"
}

kcport=$(shuf -i 20000-29999 -n 1)
kcpwd=$(openssl rand -base64 16)
configlist=$(ls server-config*)
echo 'server-config list:' $configlist
read -p "Enter remote ip port and tag. eg:1.1.1.1 1111 1 > " remote_ss_ip remote_ss_port remote_tag

#make kcptun server config file
cat >server-config-${remote_tag}.json <<EOF
{
"listen": ":${kcport}",
"target": "${remote_ss_ip}:${remote_ss_port}",
"key": "${kcpwd}",
"crypt": "aes",
"mode": "fast",
"mtu": 1350,
"sndwnd": 1024,
"rcvwnd": 1024,
"datashard": 70,
"parityshard": 30,
"dscp": 46,
"nocomp": false,
"acknodelay": false,
"nodelay": 0,
"interval": 40,
"resend": 0,
"nc": 0,
"sockbuf": 16777217,
"keepalive": 10
}
EOF

#make kcptun client config file
cat >client-config-${remote_tag}.json <<EOF
{
"localaddr": ":${remote_ss_port}",
"remoteaddr": "$(get_ip):${kcport}",
"key": "${kcpwd}",
"crypt": "aes",
"mode": "fast",
"mtu": 1350,
"sndwnd": 1024,
"rcvwnd": 1024,
"datashard": 70,
"parityshard": 30,
"dscp": 46,
"nocomp": false,
"acknodelay": false,
"nodelay": 0,
"interval": 40,
"resend": 0,
"nc": 0,
"sockbuf": 16777217,
"keepalive": 10
}
EOF

set_auto_start() {
    cat >/etc/init.d/autokcp-${remote_tag} <<EOF
#!/bin/sh

### BEGIN INIT INFO
# Provides: autokcp-${remote_tag}
# Required-Start:
# Required-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: autokcp-${remote_tag}
# Description: autokcp-${remote_tag}
### END INIT INFO
#chmod +x autokcp-${remote_tag}
#update-rc.d autokcp-${remote_tag} defaults
#update-rc.d -f autokcp-${remote_tag} remove
sleep 60
/usr/local/kcptun/server_linux_amd64 -c /usr/local/kcptun/server-config-${remote_tag}.json 2>&1 &

exit 0

EOF
    chmod +x /etc/init.d/autokcp-${remote_tag}
    update-rc.d autokcp-${remote_tag} defaults
}

# # get kcptun config
get_kcptun_client_config() {
    view_kcptunconfig=$(cat /usr/local/kcptun/client-config-${remote_tag}.json)
    echo '#### kcptun client config is:'
    echo -e "\033[1;33m${view_kcptunconfig}\033[0m"
}

set_auto_start
ufw allow "$kcport"
ufw --force enable
./server_linux_amd64 -c /usr/local/kcptun/server-config-${remote_tag}.json >/dev/null 2>&1 &

echo "server-config-${remote_tag}.json started."
get_kcptun_client_config
echo '##########'
echo 'Add more kcptun config:'
echo 'bash <(wget -qO- https://raw.githubusercontent.com/devtonull/ss/main/kcpadd.sh)'
exit
