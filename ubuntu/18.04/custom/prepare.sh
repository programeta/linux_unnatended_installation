#!/bin/bash

#Enable docker on-startup
systemctl enable docker

#Configure user "develop"
#usermod -aG docker dev
#su -l dev -c "ssh-keygen -b 2048 -t rsa -f /home/develop/.ssh/id_rsa -q -N \"\""

#Mount new harddisk
#mkdir /media/data
#mkfs.ext4 -j -L data /dev/sdb
#echo "/dev/sdb /media/data auto nosuid,nodev,nofail,x-gvfs-show,x-gvfs-name=data 0 0" >> /etc/fstab
#mount /dev/sdb /media/data

#Create data hard disk
printf "o\nn\np\n1\n\n\nw\n" | fdisk /dev/sdb
mkfs.ext4  /dev/sdb1
mkdir /media/data
#Add data to mount /media/data
cat <<EOT >> /etc/fstab
/dev/sdb1 /media/data ext4 defaults 0 2
EOT
mount /dev/sdb1 /media/data

# #Install PHP7.4
# apt-get update
# apt-get -y install software-properties-common
# add-apt-repository ppa:ondrej/php -y
# apt-get update
# apt-get install -y php7.4-{cli,bcmath,bz2,intl,gd,mbstring,mysql,zip,common}

#Install composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"

#Install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

##Add docker user (Create user, add Keygen, add Samba)
#useradd docker -u 1000 -g docker -m -s /bin/bash
#echo docker:docker | chpasswd
usermod -aG docker dev
usermod -aG sudo dev
su -l dev -c "ssh-keygen -b 2048 -t rsa -f /home/docker/.ssh/id_rsa -q -N \"\""
echo -ne "dev\dev\n" | smbpasswd -a -s docker
echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu

#Create workdir folder for docker
mkdir /media/data/docker_projects
chmod -R 775 /media/data/docker_projects
chown -R dev:dev /media/data/docker_projects
ln -s /media/data/docker_projects /home/docker/docker
chown -R dev:dev /home/docker/docker

#Add samba configuration
cat <<EOT >> /etc/samba/smb.conf

[docker_projects]
    comment = Docker projects
    path = /media/data/docker_projects
    browseable = yes
    writeable = yes
    guest ok = yes
    create mask = 0777
    directory mask = 07777
EOT

#Add Secont network configuration
cat <<EOT >> /etc/netplan/02-internal-network.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      dhcp4: no
      dhcp6: no
      addresses: [192.168.56.100/24]
      nameservers:
        addresses: [8.8.8.8, 4.4.4.4]
    eth1:
      dhcp4: no
      dhcp6: no
      addresses: [192.168.18.100/24]
      nameservers:
        addresses: [8.8.8.8, 4.4.4.4]
EOT

#Change docker folder
#service docker stop
#cp -R /var/lib/docker /root/docker_server
#mv /var/lib/docker /media/data/docker_server
mkdir /media/data/docker_server
ln -s /media/data/docker_server /var/lib/docker
#service docker start


#Change the default "/tmp" folder
mv /tmp /media/data/tmp
ln -s /media/data/tmp /tmp

#Add welcome message, before login
cat <<EOT >> /etc/issue

  Welcome to environment to work with Docker. Access to the machine through IP 192.168.56.100 using:

     SSH   --> ssh dev@192.168.56.100
     SAMBA --> \\\\\\\\192.168.56.100\\\\docker_projects

EOT
