#!/bin/sh

echo -e "\e[32m \e[1mUpdate & Upgrade\e[0m"

apt update && apt upgrade -y

echo -e "\e[32m \e[1mInstall Packets\e[0m"

apt-get install openssh-server liberror-perl rsync git build-essential bsdtar net-tools mcrypt curl -y

echo -e "\e[32m \e[1mInstall 3Proxy\e[0m"

git clone https://github.com/z3APA3A/3proxy.git

cd 3proxy/

cp src/3proxy /usr/local/etc/3proxy/bin/

ls /usr/local/etc/3proxy/bin/

make -f Makefile.Linux

ls bin/

cp bin/3proxy /usr/local/etc/3proxy/bin/

ls

cp scripts/init.d/3proxy.sh /etc/init.d/

chmod +x /etc/init.d/3proxy.sh

cp bin/3proxy  /bin/

mkdir /etc/3proxy

systemctl daemon-reload

systemctl enable 3proxy

service 3proxy start

echo -e "\e[32m \e[1mUpdates and Installations are Complete\e[0m"


whiptail --title "ProxyV6" --msgbox "Installation is starting. Fill in the steps completely." 8 78

IPv6=$(whiptail --inputbox "What is the server IPv6 subnet? Sample: 2000:6580:2::1" 8 78 --title "ProxyV6" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
SetupControl=True
IPv6Subnet=$IPv6
else
exit
fi

ProxyCount=$(whiptail --inputbox "How many proxies would you like to create? Sample: 100" 8 78 --title "ProxyV6" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
SetupControl=True
ProxyAdedi=$ProxyCount
else
exit
fi

Interface=$(whiptail --inputbox "What is the name of the interface to which IPv6 addresses are attached? Sample: eth1" 8 78 --title "ProxyV6" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
SetupControl=True
HangiETH=$Interface
else
exit
fi


UserName=$(whiptail --inputbox "What is the username for the proxy? Sample: Alptekin" 8 78 --title "ProxyV6" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
SetupControl=True
UserAdi=$UserName
else
exit
fi


Password=$(whiptail --inputbox "What is the user password? Sample: 123456" 8 78 --title "ProxyV6" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
SetupControl=True
UserPass=$Password
else
exit
fi





if [[ $SetupControl = True ]]
then

IPv4_Prefix=$IPv4;
IPv6_Prefix=$IPv6Subnet;
interface=$HangiETH;
UserName=$UserAdi;
Password=$UserPass;
ProxyQuantity=$ProxyAdedi;



declare -a IPv6_Array

random() {
        tr </dev/urandom -dc A-Za-z0-9 | head -c5
        echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)


for ((i=1;i<=$ProxyQuantity;i++));
do

 ip64() {
        echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
        }
 IPv6_Array+=("$IPv6_Prefix:$(ip64):$(ip64):$(ip64)")

done


cat <<EOF >IPv6.conf
daemon
nserver 1.1.1.1
maxconn 100
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
internal $IPv4_Prefix
flush

force
users $UserName:CL:$Password
auth strong
allow $UserName * * * *

$(
Port=30000
for i in "${IPv6_Array[@]}";
do
let "Port += 1"
echo proxy -6 -n -a -p$Port -e$i;
done
)

EOF

cp IPv6.conf /etc/3proxy/3proxy.cfg


cat <<EOF >IPv6_ifconfig.sh
$(
for i in "${IPv6_Array[@]}";
do
echo ifconfig $interface inet6 add $i/64
done
)

EOF

bash ./IPv6_ifconfig.sh

systemctl stop 3proxy.service
systemctl start 3proxy.service

rm IPv6_ifconfig.sh
rm IPv6.conf

echo -e "\e[32m \e[1mIPv6 Proxy List\e[0m"
echo ""
echo ""
echo -e "\e[32m \e[1mUserName:\e[0m"
echo " $UserName"
echo -e "\e[32m \e[1mPassword:\e[0m"
echo " $Password"
echo ""
Port=30000
for i in "${IPv6_Array[@]}";
do
let "Port += 1"
echo "TCP/$Port    IPv6: $i"
done






fi
