# remove if the package exist
yum remove -y pptpd ppp dkms
rm -rf /etc/pptpd.conf
rm -rf /etc/ppp

# get the right archive package
arch=`uname -m`
wget http://poptop.sourceforge.net/yum/stable/packages/pptpd-1.4.0-1.el6.$arch.rpm

# install depend package
yum -y install make libpcap iptables gcc-c++ logrotate tar cpio perl pam tcp_wrappers dkms kernel_ppp_mppe ppp
rpm -Uvh pptpd-1.4.0-1.el6.$arch.rpm
rm -rf pptpd-1.4.0-1.el6.$arch.rpm

# install jq cmd
wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
mv jq-linux64 jq
chmod 777 jq
mv jq /usr/bin

# get realip
curl ipinfo.io >> ipinfo.json
ip=`cat ipinfo.json | jq '.ip'`
ip=${ip:1}
ip=${ip%\"*}
echo $ip
rm -rf ipinfo.json

# set pptpd config
echo "debug" >> /etc/pptpd.conf
echo "ppp /usr/sbin/pppd" >> /etc/pptpd.conf
echo "option /etc/ppp/options.pptpd" >> /etc/pptpd.conf
echo "localip $ip" >> /etc/pptpd.conf
echo "remoteip 192.168.0.2-4" >> /etc/pptpd.conf
echo "ms-dns 8.8.8.8" >> /etc/ppp/options
echo "ms-dns 8.8.4.4" >> /etc/ppp/options

# set default username and password
echo "test pptpd 123456  *" >> /etc/ppp/chap-secrets

# set iptales
iptables -t nat -F
iptables -t nat -A POSTROUTING -s 192.168.0.2/24 -j SNAT --to $ip
echo 1 > /proc/sys/net/ipv4/ip_forward

service iptables save

# auto start
chkconfig iptables on
chkconfig pptpd on

# start service
service iptables start
service pptpd start

echo "VPN service is installed, your VPN username and password in /etc/ppp/chap-secrets."