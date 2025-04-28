#! /bin/bash

# Генерация ключей + выдача их + сканирование отпечатков (НИКОГДА ТАК НЕ ДЕЛАЕТЕ НА РЕАЛЬНОМ ОБОРУДОВАНИИ, ТАК КАК ЭТО ЛОГИРУЕТСЯ И ЗЛОУМЫШЛЕННИК ПОЛУЧИТ ДОСТУП К ВАШЕЙ СЕТИ, ЗДЕСЬ ОНО СДЕЛАНО В РАМКАХ АВТОМАТИЗАЦИИ)

ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
ssh-keyscan -H 44.44.44.2 >> ~/.ssh/known_hosts
apt-get install sshpass
sshpass -p 'P@ssw0rd' ssh-copy-id student@44.44.44.2
ssh-keyscan -H 22.22.22.2 >> ~/.ssh/known_hosts
sshpass -p 'P@ssw0rd' ssh-copy-id student@22.22.22.2
ssh-keyscan -H 33.33.33.2 >> ~/.ssh/known_hosts
sshpass -p 'P@ssw0rd' ssh-copy-id root@33.33.33.2

# Добавление resolv конфига через ssh.

cat << EOF > nameserver.sh
#! /bin/bash
echo Starting on $(hostname -s)

echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo Ended
EOF

scp nameserver.sh student@44.44.44.2:/home/student/nameserver.sh
scp nameserver.sh student@22.22.22.2:/home/student/nameserver.sh
scp nameserver.sh root@33.33.33.2:/root/nameserver.sh

echo "sudo chmod +x nameserver.sh" | ssh student@44.44.44.2
echo "sudo chmod +x nameserver.sh" | ssh student@22.22.22.2
echo "chmod +x nameserver.sh" | ssh root@33.33.33.2

echo "sudo ./nameserver.sh" | ssh student@44.44.44.2
echo "sudo ./nameserver.sh" | ssh student@22.22.22.2
echo "./nameserver.sh" | ssh root@33.33.33.2

# Обновление пакетов.

echo "sudo apt-get update" | ssh student@44.44.44.2
echo "sudo apt-get update" | ssh student@22.22.22.2
echo "apt-get update" | ssh root@33.33.33.2

# Установка ansible

apt-get install ansible -y

# Настройка хостов

cat << EOF > /etc/ansible/hosts
VMs:
 hosts:
  BR-RTR:
   ansible_host: 44.44.44.2
   ansible_user: student
  HQ-RTR:
   ansible_host: 22.22.22.2
   ansible_user: student
  HQ-SRV:
   ansible_host: 11.11.11.2
   ansible_user: student
   ansible_port: 2222
  BR-SRV:
   ansible_host: 55.55.55.2
   ansible_user: student
  CLI:
   ansible_host: 33.33.33.2
   ansible_user: root
EOF

# Вставка строк в ansible.cfg
sed '10 a\
ansible_python_interpreter=/usr/bin/python3\
interpreter_python=auto_silent\
ansible_host_key_checking=false' /etc/ansible/ansible.cfg > ansible.cfg
rm -rf /etc/ansible/ansible.cfg
mv ansible.cfg /etc/ansible/ansible.cfg

# Копирование и активация PlayBook-a

cp /root/DEMO-2024-TESTING/BR-RTR.yml /root/BR-RTR.yml
ansible-playbook BR-RTR.yml
cp /root/DEMO-2024-TESTING/HQ-RTR.yml /root/HQ-RTR.yml
ansible-playbook HQ-RTR.yml

# Отправка Backup-скрипта HQ-RTR|HQ-SRV

scp DEMO-2024-TESTING/backup_script.sh student@22.22.22.2:/home/student/backup_script.sh
scp DEMO-2024-TESTING/backup_script.sh student@44.44.44.2:/home/student/backup_script.sh

echo "sudo chmod +x backup_script.sh" | ssh student@44.44.44.2
echo "sudo chmod +x backup_script.sh" | ssh student@22.22.22.2

echo "sudo ./backup_script.sh" | ssh student@44.44.44.2
echo "sudo ./backup_script.sh" | ssh student@22.22.22.2

# Генерация ключей ed25519 (Отпечаток для входа в root без необходимости регистрации)

ssh-keygen -t ed25519  -b 4096 -N "" -f /root/.ssh/id_ed25519 -q

# Отправка ключей на HQ-RTR|BR-RTR|HQ-SRV|BR-SRV (К этому моменту у HQ-SRV должен выдасться айпишник по DHCP, но наверное чтобы не делать лишних движений, сделать статическую маршрутизацию, потом уже будет переделано под DHCP под конец)

scp /root/.ssh/id_ed25519.pub student@22.22.22.2:/home/student/id
scp /root/.ssh/id_ed25519.pub student@44.44.44.2:/home/student/id
echo "Копирование ключей часть 1"
sleep 5
ssh-keyscan -H 55.55.55.2 >> ~/.ssh/known_hosts
ssh-keyscan -p 2222 -H 11.11.11.2 >> ~/.ssh/known_hosts
echo "Сканирование"
sleep 5
sshpass -p "P@ssw0rd" ssh-copy-id -p 2222 student@11.11.11.2
sshpass -p "P@ssw0rd" ssh-copy-id student@55.55.55.2
echo "Копирование ключа rsa."
sleep 5
scp -P 2222 /root/.ssh/id_ed25519.pub student@11.11.11.2:/home/student/id
scp /root/.ssh/id_ed25519.pub student@55.55.55.2:/home/student/id
echo "Копирование ключей часть 2"

# Копирование ключей для авторизации под root

echo "sudo cp /home/student/id /root/.ssh/authorized_keys" | ssh student@11.11.11.2 -p 2222
echo "sudo cp /home/student/id /root/.ssh/authorized_keys" | ssh student@22.22.22.2
echo "sudo cp /home/student/id /root/.ssh/authorized_keys" | ssh student@44.44.44.2
echo "sudo cp /home/student/id /root/.ssh/authorized_keys" | ssh student@55.55.55.2

# До обновляем машины HQ-SRV, BR-SRV, Ибо только сейчас ISP получил доступ к ним


scp -P 2222 nameserver.sh student@11.11.11.2:/home/student/nameserver.sh
scp nameserver.sh student@55.55.55.2:/home/student/nameserver.sh

echo "sudo chmod +x nameserver.sh" | ssh student@11.11.11.2 -p 2222
echo "sudo chmod +x nameserver.sh" | ssh student@55.55.55.2

echo "sudo ./nameserver.sh" | ssh student@11.11.11.2 -p 2222
echo "sudo ./nameserver.sh" | ssh student@55.55.55.2

echo "apt-get update" | ssh root@11.11.11.2 -p 2222
echo "apt-get update" | ssh root@55.55.55.2

# Переделывание файла hosts.

cat << EOF > /etc/ansible/hosts
VMs:
 hosts:
  BR-RTR:
   ansible_host: 44.44.44.2
   ansible_user: root
  HQ-RTR:
   ansible_host: 22.22.22.2
   ansible_user: root
  HQ-SRV:
   ansible_host: 11.11.11.2
   ansible_user: root
   ansible_port: 2222
  BR-SRV:
   ansible_host: 55.55.55.2
   ansible_user: root
  CLI:
   ansible_host: 33.33.33.2
   ansible_user: root
EOF

# ============================================= Первый модуль окончен. =============================================

echo "============================================= Первый модуль окончен. ============================================="

# ============================================= Начало второго модуля.=============================================

echo "============================================= Начало второго модуля.============================================="
# Переименование хостов

echo "hostnamectl hostname hq-srv.hq.work" | ssh root@11.11.11.2 -p 2222
echo "domainname hq.work" | ssh root@11.11.11.2 -p 2222

# Установка утилит

echo "apt-get install samba-dc -y" | ssh root@11.11.11.2 -p 2222
echo "apt-get install bind-utils -y" | ssh root@11.11.11.2 -p 2222

# Перезапуск всех устройств

echo "hostnamectl hostname HQ-SRV" | ssh root@11.11.11.2 -p 2222
echo "hostnamectl hostname CLI" | ssh root@33.33.33.2
echo "reboot" | ssh root@33.33.33.2
ansible HQ-SRV,HQ-RTR,BR-SRV,BR-RTR -m reboot
echo "Перезапуск успешен"

# Изменение файла dhcpd.conf и перезапуск DHCP

cat << EOF > /root/dhcpd.conf

#See dhcpd.conf(5) for further configuration

ddns-update-style none;

subnet 11.11.11.0 netmask 255.255.255.192 {
	option routers			11.11.11.1;
	option subnet-mask		255.255.255.192;

	option nis-domain		"domain.org";
	option domain-name		"hq.work";
	option domain-name-servers	11.11.11.2;
	
 	range dynamic-bootp 11.11.11.2 11.11.11.60;
	default-lease-time 21600;
	max-lease-time 43200;

	host HQ-SRV
	{
	hardware ethernet 00:0C:29:0B:F2:1A;
	fixed-address 11.11.11.2;
	}
}
EOF

scp /root/dhcpd.conf root@22.22.22.2:/etc/dhcp/dhcpd.conf

echo "systemctl restart dhcpd" | ssh root@22.22.22.2

# Удаление файла smb.conf на HQ-SRV и настройка тулов

echo "rm -rf /etc/samba/smb.conf" | ssh root@11.11.11.2 -p 2222

echo "samba-tool domain provision --realm=HQ.WORK --domain=HQ --adminpass=P@ssw0rd --dns-backend=SAMBA_INTERNAL --server-role=dc --option='dns forwarder=8.8.8.8'" | ssh root@11.11.11.2 -p 2222

echo "systemctl enable --now samba.service" | ssh root@11.11.11.2 -p 2222

cat << EOF > /root/resolv.conf
domain hq.work
nameserver 11.11.11.2
nameserver 8.8.8.8
EOF

scp -P 2222 /root/resolv.conf root@11.11.11.2:/etc/resolv.conf 

echo "samba-tool dns zonecreate hq-srv.hq.work branch.work -U administrator --password=P@ssw0rd" | ssh root@11.11.11.2 -p 2222
echo "samba-tool dns zonecreate hq-srv.hq.work 11.11.11.in-addr.arpa -U administrator --password=P@ssw0rd" | ssh root@11.11.11.2 -p 2222
echo "samba-tool dns zonecreate hq-srv.hq.work 55.55.55.in-addr.arpa -U administrator --password=P@ssw0rd" | ssh root@11.11.11.2 -p 2222
sleep 5
echo "samba-tool dns add hq-srv.hq.work hq.work hq-r A 11.11.11.1 -U administrator --password=P@ssw0rd" | ssh root@11.11.11.2 -p 2222
echo "samba-tool dns add hq-srv.hq.work branch.work br-r A 55.55.55.1 -U administrator --password=P@ssw0rd" | ssh root@11.11.11.2 -p 2222
echo "samba-tool dns add hq-srv.hq.work branch.work br-srv A 55.55.55.2 -U administrator --password=P@ssw0rd" | ssh root@11.11.11.2 -p 2222
sleep 5
echo "samba-tool dns add hq-srv.hq.work 11.11.11.in-addr.arpa 1 PTR hq-r.hq.work -U administrator --password=P@ssw0rd" | ssh root@11.11.11.2 -p 2222
echo "samba-tool dns add hq-srv.hq.work 11.11.11.in-addr.arpa 2 PTR hq-srv.hq.work -U administrator --password=P@ssw0rd" | ssh root@11.11.11.2 -p 2222
echo "samba-tool dns add hq-srv.hq.work 55.55.55.in-addr.arpa 1 PTR br-r.branch.work -U administrator --password=P@ssw0rd" | ssh root@11.11.11.2 -p 2222

# Конфигурация временного подключения у HQ-SRV и CLI

cat << EOF > /root/heh.
TYPE=eth
BOOTPROTO=static
DISABLED=no
CONFIG_IPV4=yes
NM_CONTROLLED=no
EOF

echo "mkdir -p /etc/net/ifaces/ens224" | ssh root@33.33.33.2
echo "mkdir -p /etc/net/ifaces/ens224" | ssh root@11.11.11.2 -p 2222

scp -P 2222 heh. root@11.11.11.2:/etc/net/ifaces/ens224/options
scp heh. root@33.33.33.2:/etc/net/ifaces/ens224/options

echo "echo 66.66.66.1/30 > /etc/net/ifaces/ens224/ipv4address" | ssh root@33.33.33.2
cat << EOF > /root/resolv.conf.s
nameserver 11.11.11.2
search hq.work branch.work
EOF
scp resolv.conf.s root@33.33.33.2:/etc/net/ifaces/ens224/resolv.conf

echo "echo 66.66.66.2/30 > /etc/net/ifaces/ens224/ipv4address" | ssh root@11.11.11.2 -p 2222

# Добавление CLI и BR-SRV в контроллер домена

echo "apt-get install task-auth-ad-sssd -y" | ssh root@33.33.33.2
echo "reboot" | ssh root@33.33.33.2
echo "apt-get install task-auth-ad-sssd -y" | ssh root@55.55.55.2

echo "apt-get install bind-utils -y" | ssh root@33.33.33.2
echo "apt-get install bind-utils -y" | ssh root@55.55.55.2

echo "system-auth write ad hq.work cli HQ 'administrator' 'P@ssw0rd'" | ssh root@33.33.33.2
scp resolv.conf.s root@55.55.55.2:/etc/net/ifaces/ens192/resolv.conf
echo "systemctl restart network" | ssh root@55.55.55.2
echo "system-auth write ad hq.work br-srv HQ 'administrator' 'P@ssw0rd'" | ssh root@55.55.55.2


# Добавление пользователей в домен

cat << EOF | ssh root@33.33.33.2
echo P@ssw0rd | adcli join hq.work --stdin-password
echo P@ssw0rd | adcli create-user --domain=hq.work Admin -x
echo P@ssw0rd | adcli create-user --domain=hq.work 'Branch admin' -x
echo P@ssw0rd | adcli create-user --domain=hq.work 'Network admin' -x
echo P@ssw0rd | adcli create-group --domain=hq.work Admins -x
echo P@ssw0rd | adcli create-group --domain=hq.work 'Branch admins' -x
echo P@ssw0rd | adcli create-group --domain=hq.work 'Network admin' -x
echo P@ssw0rd | adcli add-member --domain=hq.work Admins Admin -x -v
echo P@ssw0rd | adcli add-member --domain=hq.work 'Branch admins' 'Branch admin' -x -v
echo P@ssw0rd | adcli add-member --domain=hq.work 'Network admin' 'Network admin' -x -v
EOF

# Начало конфигурации файлового сервера на HQ-SRV

cat << EOF | ssh root@11.11.11.2 -p 2222
mkdir /opt/{branch,network,admin}
chmod 777 /opt/{branch,network,admin}

cat << EOF >> /etc/samba/smb.conf
[Branch_Files]
	path = /opt/branch
 	writable = yes
  	read only = no
	valid users = @"HQ\Branch admins"
[Network]
	path = /opt/network
 	writable = yes
  	read only = no
   	valid users = @"HQ\Network admins"
[Admin_Files]
	path=/opt/admin
 	writable=yes
  	read only = no
   	valid users = @"HQ\Admins"
EOF

cat << EOF | ssh root@55.55.55.2
apt-get install pam_mount -y
apt-get install cifs-utils –y
apt-get install systemd-settings-enable-kill-user-processes -y
EOF

ansible BR-SRV -m reboot

cat << EOF | ssh root@55.55.55.2

cat << EOF >> /etc/pam.d/system-auth
session		[success=1 default=ignore] pam_succeed_if.so service = systemd-user quiet
session		optional	pam_mount.so disable_interactive
EOF

ansible-playbook /root/DEMO-2024-TESTING/pam.yml
