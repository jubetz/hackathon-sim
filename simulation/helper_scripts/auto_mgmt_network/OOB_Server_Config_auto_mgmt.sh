#!/bin/bash
# Created by Topology-Converter v4.7.1
#    Template Revision: v4.7.1
#    https://github.com/cumulusnetworks/topology_converter
#    using topology data from: cldemo2.dot

echo "################################################"
echo "  Running Automatic Management Server Setup..."
echo "################################################"
echo -e "\n This script assumes an Ubuntu18.04 server."
echo " Detected vagrant user is: $username"


#######################
#       KNOBS
#######################

REPOSITORY="https://gitlab.com/cumulus-consulting/goldenturtle/"
REPONAME="cldemo2"

#Install Automation Tools
puppet=0
ansible=1
ansible_version=2.9.13

#######################

username=$(cat /tmp/normal_user)

install_puppet(){
    echo " ### Adding Puppet Repositories... ###"
    wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
    dpkg -i puppetlabs-release-pc1-xenial.deb
    echo " ### Updating APT Repository... ###"
    apt-get update -y
    echo " ### Installing Puppet ###"
    apt-get install puppetserver -qy
    echo " ### Setting up Puppet ###"
    rm -rf /etc/puppetlabs/code/environments/production
    sed -i 's/-Xms2g/-Xms512m/g' /etc/default/puppetserver
    sed -i 's/-Xmx2g/-Xmx512m/g' /etc/default/puppetserver
    echo "*" > /etc/puppetlabs/puppet/autosign.conf
    sed -i 's/192.168.200.1/192.168.200.1 puppet /g'>> /etc/hosts
}

install_ansible(){
    echo " ### Installing Ansible... ###"
    # See: https://bugs.launchpad.net/ubuntu/+source/ansible/+bug/1833013
    apt-get -q --option "Dpkg::Options::=--force-confold" --assume-yes install libssl1.1

    apt-get install -qy sshpass libssh-dev python3-dev libssl-dev libffi-dev python3-pip
    /usr/bin/pip3 install setuptools --upgrade
    /usr/bin/pip3 install paramiko netaddr cryptography
    /usr/bin/pip3 install ansible==$ansible_version --upgrade
}

set -e

## MOTD
echo " ### Overwriting MOTD ###"
cat <<EOT > /etc/motd.base64
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIF8NChtbMDs0
MDszN20bWzZDG1szMW1fX19fX19fG1szN20gICAbWzE7MzJteBtbMG0gG1szMm14G1szN20gG1sz
Mm14G1szN20bWzI3Q3wgfA0KIBtbMzJtLl8bWzM3bSAgG1szMW08X19fX19fXxtbMTszM21+G1sw
bSAbWzMybXgbWzM3bSAbWzE7MzJtWBtbMG0gG1szMm14G1szN20gICBfX18gXyAgIF8gXyBfXyBf
X18gIF8gICBffCB8XyAgIF8gX19fDQobWzMybSgbWzM3bScgG1szMm1cG1szN20gIBtbMzJtLCcg
G1sxOzMzbXx8G1swOzMybSBgLBtbMzdtICAgIBtbMzJtIBtbMzdtICAgLyBfX3wgfCB8IHwgJ18g
YCBfIFx8IHwgfCB8IHwgfCB8IC8gX198DQogG1szMm1gLl86XhtbMzdtICAgG1sxOzMzbXx8G1sw
bSAgIBtbMzJtOj4bWzM3bRtbNUN8IChfX3wgfF98IHwgfCB8IHwgfCB8IHxffCB8IHwgfF98IFxf
XyBcDQobWzVDG1szMm1eVH5+fn5+flQbWzM3bScbWzdDXF9fX3xcX18sX3xffCB8X3wgfF98XF9f
LF98X3xcX18sX3xfX18vDQobWzVDG1szMm1+IhtbMzdtG1s1QxtbMzJtfiINChtbMzdtG1swMG0N
Cg0KIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMj
IyMjIyMjIyMjIyMjIyMjIyMjIyMjIw0KIw0KIyAgICAgICAgIE91dCBPZiBCYW5kIE1hbmFnZW1l
bnQgU2VydmVyIChvb2ItbWdtdC1zZXJ2ZXIpDQojDQojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMj
IyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjDQo=
EOT
base64 -d /etc/motd.base64 > /etc/motd
rm /etc/motd.base64
chmod 755 /etc/motd

echo " ### Setting pre-login banner ###"
cat <<EOT > /etc/issue
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   Welcome to \n
   Login with: cumulus/CumulusLinux!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

EOT
cp /etc/issue /etc/issue.net
chmod 755 /etc/issue /etc/issue.net

echo " ### Overwriting DNS Server to 8.8.8.8 ###"
#Required because the installation of DNSmasq throws off DNS momentarily
sed -i '/DNS=/d' /etc/systemd/resolved.conf
sed -i '/\[Resolve\]/a DNS=8.8.8.8 1.1.1.1' /etc/systemd/resolved.conf
sed -i 's/DNSSEC=yes/DNSSEC=no/' /etc/systemd/resolved.conf
systemctl restart systemd-resolved.service

echo " ### Updating APT Repository... ###"
export DEBIAN_FRONTEND=noninteractive

echo "Add Cumulus Apps Pubkey"
wget -q -O- https://apps3.cumulusnetworks.com/setup/cumulus-apps-deb.pubkey | apt-key add - 2>&1

echo "Adding Cumulus Apps Repo"
echo "deb http://apps3.cumulusnetworks.com/repos/deb bionic netq-latest" > /etc/apt/sources.list.d/netq.list

apt-get update -y

echo " ### Installing Packages... ###"
apt-get install -y htop isc-dhcp-server tree apache2 git python-pip python3-pip dnsmasq apt-cacher-ng lldpd ntp ifupdown2

echo " ### Overwriting /etc/network/interfaces ###"
cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback


auto vagrant
iface vagrant inet dhcp


#auto eth0
#iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 192.168.200.1/24
EOT

# We don't apply config here because interfaces have not been remapped.
#    The subsequent reboot will apply the configuration above anyways.
#echo " ### Applying Network Configuration via IFUPDOWN2... ###"
#/sbin/ifreload -a

if [ $puppet -eq 1 ]; then
    echo " ### Installing Puppet ### "
    install_puppet
fi
if [ $ansible -eq 1 ]; then
    echo " ### Installing Ansible ### "
    install_ansible
fi

echo " ### Configure NTP... ###"
echo "tinker panic 0" >> /etc/ntp.conf

#cat <<EOT > /etc/ntp.conf
#tinker panic 0
#
#driftfile /var/lib/ntp/ntp.drift
#statistics loopstats peerstats clockstats
#filegen loopstats file loopstats type day enable
#filegen peerstats file peerstats type day enable
#filegen clockstats file clockstats type day enable
#
#server 0.cumulusnetworks.pool.ntp.org iburst
#server 1.cumulusnetworks.pool.ntp.org iburst
#server 2.cumulusnetworks.pool.ntp.org iburst
#server 3.cumulusnetworks.pool.ntp.org iburst
#
# By default, exchange time with everybody, but don't allow configuration.
#restrict -4 default kod notrap nomodify nopeer noquery
#restrict -6 default kod notrap nomodify nopeer noquery
#
# Local users may interrogate the ntp server more closely.
#restrict 127.0.0.1
#restrict ::1
#
#interface listen eth1
#EOT

echo " ### Creating cumulus user ###"
useradd -m cumulus -c "Cumulus User" -s /bin/bash
echo 'cumulus:CumulusLinux!' | chpasswd

echo " ### Setting Up DHCP ###"
mv /home/$username/dhcpd.conf /etc/dhcp/dhcpd.conf
mv /home/$username/dhcpd.hosts /etc/dhcp/dhcpd.hosts
chmod 755 -R /etc/dhcp/*
systemctl restart isc-dhcp-server

echo " ### Setting up ZTP ###"
mv /home/$username/cumulus-ztp /var/www/html/cumulus-ztp

echo " ### Setting Up Hostfile ###"
mv /home/$username/hosts /etc/hosts
chmod 755 /etc/hosts

echo " ### Moving Ansible Hostfile into place ###"
mkdir -p /etc/ansible
mv /home/$username/ansible_hostfile /etc/ansible/hosts

echo " ### Creating SSH keys for cumulus user ###"
mkdir /home/cumulus/.ssh
/usr/bin/ssh-keygen -b 2048 -t rsa -f /home/cumulus/.ssh/id_rsa -q -N ""
cp /home/cumulus/.ssh/id_rsa.pub /home/cumulus/.ssh/authorized_keys

echo " ### Appending Vagrant generated pub-key to the Cumulus user account ###"
cat /home/vagrant/.ssh/authorized_keys >> /home/cumulus/.ssh/authorized_keys

chown -R cumulus:cumulus /home/cumulus/
chown -R cumulus:cumulus /home/cumulus/.ssh
chmod 700 /home/cumulus/.ssh/
chmod 600 /home/cumulus/.ssh/*
chown cumulus:cumulus /home/cumulus/.ssh/*

echo " ### Copying SSH keys to $username ###"
cp /home/cumulus/.ssh/id_rsa* /home/$username/.ssh/

echo " ### Copying SSH config file to $username and cumulus user ###"
mv /home/$username/ssh_config /home/$username/.ssh/config
chown -R $username:$username /home/$username/.ssh/
cp /home/$username/.ssh/config /home/cumulus/.ssh/config
chown cumulus:cumulus /home/cumulus/.ssh/config
#stage ssh key for air-one click production ready automation

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDN1byqAh0Wt3ykIuDsPYZm/RWvSquY0Gi3LIpiKhMrJ7nm8HFG6prLWXuFjhSJFvYH8g9Jm52Gl8qzqthYD3/vG+wyly0WVbOjWcrsq2fJFwqvGerOj/u3w+UpyEYpM42xz00difSjO3CvupUJB8Q48S8S3vEbr2i7rNUtQAkG+G2pQJMZvGrem8KYx/TXm1UN2p/1gb5OLuUBdbUeL10Ibb17DxEBwPUvxgxjIlH368RLKuEkH7b4VIyjM+YzLu317spdFqo4wWWF4tjp7F0F4uTe0PyMrGjQBaznL3UmxmBiMwGri+v032EQg44ItrxkAg50P6f6dFGCY0Rvie1Z air-admin@mgmt" >>/home/cumulus/.ssh/authorized_keys

echo "<html><h1>You've come to the OOB-MGMT-Server.</h1></html>" > /var/www/html/index.html

echo " ### Copying Key into /var/www/html... ###"
cp /home/cumulus/.ssh/id_rsa.pub /var/www/html/authorized_keys
chmod 777 -R /var/www/html/*

echo " ### Disabling SSH Key Checking ###"
echo 'Host *' > /home/cumulus/.ssh/config
echo '    StrictHostKeyChecking no' >> /home/cumulus/.ssh/config
chown cumulus /home/cumulus/.ssh/config

echo " ###Making cumulus passwordless sudo ###"
echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus

echo ' ### Setting UP NAT and Routing on MGMT server... ### '
echo '#!/bin/bash' > /etc/rc.local
echo '/sbin/iptables -t nat -A POSTROUTING -o vagrant -j MASQUERADE' >> /etc/rc.local
echo '/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE' >> /etc/rc.local
chmod +x /etc/rc.local
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/98-ipforward.conf

echo "Enable and start NTP"
timedatectl set-ntp off
/lib/systemd/systemd-sysv-install enable ntp

echo " ### Creating turnup.sh script ###"
    cat <<EOT >> /home/cumulus/turnup.sh
git clone $REPOSITORY
EOT

if [ $puppet -eq 1 ]; then
    cat <<EOT >> /home/cumulus/turnup.sh
sudo rm -rf /etc/puppetlabs/code/environments/production
sudo ln -s  /home/cumulus/$REPONAME/puppet/ /etc/puppetlabs/code/environments/production
sudo /opt/puppetlabs/bin/puppet module install puppetlabs-stdlib
#sudo bash -c 'echo "certname = 192.168.200.1" >> /etc/puppetlabs/puppet/puppet.conf'
echo " ### Starting PUPPET Master ###"
echo "     (this may take a while 30 secs or so...)"
sudo systemctl restart puppetserver.service
EOT
fi

if [ $ansible -eq 1 ]; then
    cat <<EOT >> /home/cumulus/turnup.sh
# Add any ansible specific steps here
EOT
fi
chmod +x /home/cumulus/turnup.sh

echo "Update DNSmasq config to resolve for local domain .simulation"
echo "domain=simulation" >> /etc/dnsmasq.conf
echo "local=/simulation/" >> /etc/dnsmasq.conf
echo "expand-hosts" >> /etc/dnsmasq.conf

echo " ### creating .gitconfig for cumulus user"
cat <<EOT >> /home/cumulus/.gitconfig
[push]
  default = matching
[color]
    ui = true
[credential]
    helper = cache --timeout=3600
[core]
    editor = vim
EOT

echo "Enable ipv6"
sed -i 's/net.ipv6.conf.all.disable_ipv6\ =\ 1/net.ipv6.conf.all.disable_ipv6\ =\ 0/' /etc/sysctl.conf

echo "############################################"
echo "      DONE!"
echo "############################################"
