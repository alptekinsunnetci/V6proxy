#!/bin/bash

set -e
set -u 

GREEN="\e[32m"
BOLD="\e[1m"
RESET="\e[0m"

log() {
    echo -e "${GREEN}${BOLD}$1${RESET}"
}

log "Update & Upgrade"
apt update && apt upgrade -y

log "Install Packets"
apt-get install -y openssh-server liberror-perl rsync git build-essential bsdtar net-tools mcrypt curl

log "Install 3Proxy"
if ! git clone https://github.com/z3APA3A/3proxy.git; then
    log "Git Clone Failed, Exiting..."
    exit 1
fi

cd 3proxy
make -f Makefile.Linux
install -Dm755 bin/3proxy /usr/local/etc/3proxy/bin/3proxy
install -Dm755 scripts/init.d/3proxy.sh /etc/init.d/3proxy.sh
chmod +x /etc/init.d/3proxy.sh
mkdir -p /etc/3proxy
systemctl daemon-reload
systemctl enable 3proxy
service 3proxy start

log "Updates and Installations are Complete"

whiptail_prompt() {
    local message="$1"
    local title="$2"
    whiptail --inputbox "$message" 8 78 --title "$title" 3>&1 1>&2 2>&3
}

IPv6=$(whiptail_prompt "What is the server IPv6 subnet? Sample: 2000:6580:2::1" "ProxyV6")
ProxyCount=$(whiptail_prompt "How many proxies would you like to create? Sample: 100" "ProxyV6")
Interface=$(whiptail_prompt "What is the name of the interface to which IPv6 addresses are attached? Sample: eth1" "ProxyV6")
UserName=$(whiptail_prompt "What is the username for the proxy? Sample: Alptekin" "ProxyV6")
Password=$(whiptail_prompt "What is the user password? Sample: 123456" "ProxyV6")

log "Setting Up Proxies"

IPv6_Array=()
array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)

generate_ipv6_suffix() {
    echo "${array[RANDOM % 16]}${array[RANDOM % 16]}${array[RANDOM % 16]}${array[RANDOM % 16]}"
}

for ((i = 1; i <= ProxyCount; i++)); do
    IPv6_Array+=("$IPv6:$(generate_ipv6_suffix):$(generate_ipv6_suffix):$(generate_ipv6_suffix)")
done

cat <<EOF >/etc/3proxy/3proxy.cfg
daemon
nserver 1.1.1.1
maxconn 100
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
internal 0.0.0.0
flush
auth strong
users $UserName:CL:$Password
allow $UserName

$(
Port=30000
for ip in "${IPv6_Array[@]}"; do
    ((Port++))
    echo "proxy -6 -n -a -p$Port -e$ip"
done
)
EOF

cat <<EOF >add_ipv6.sh
#!/bin/bash
$(
for ip in "${IPv6_Array[@]}"; do
    echo "ifconfig $Interface inet6 add $ip/64"
done
)
EOF

bash add_ipv6.sh

systemctl restart 3proxy

rm -f add_ipv6.sh

log "IPv6 Proxy List"
echo "Username: $UserName"
echo "Password: $Password"

Port=30000
for ip in "${IPv6_Array[@]}"; do
    ((Port++))
    echo "TCP/$Port    IPv6: $ip"
done
