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

ssh-keyget -t ed25519

# Отправка ключей на HQ-RTR|BR-RTR|HQ-SRV|BR-SRV (К этому моменту у HQ-SRV должен выдасться айпишник по DHCP, но наверное чтобы не делать лишних движений, сделать статическую маршрутизацию, потом уже будет переделано под DHCP под конец)

scp /root/.ssh/id_ed25519.pub student@22.22.22.2:/home/student/id
scp /root/.ssh/id_ed25519.pub student@44.44.44.2:/home/student/id
ssh-keyscan -H 55.55.55.2 >> ~/.ssh/known_hosts
ssh-keyscan -p 2222 -H 11.11.11.2 >> ~/.ssh/known_hosts
sshpass -p "P@ssw0rd" ssh-copy-id -p 2222 student@11.11.11.2
sshpass -p "P@ssw0rd" ssh-copy-id student@55.55.55.2
scp /root/.ssh/id_ed25519.pub student@11.11.11.2:/home/student/id
scp /root/.ssh/id_ed25519.pub student@55.55.55.2:/home/student/id

# Копирование ключей для авторизации под root

echo "sudo mkdir -p /root/.ssh" | ssh student@11.11.11.2
echo "sudo mkdir -p /root/.ssh" | ssh student@22.22.22.2
echo "sudo mkdir -p /root/.ssh" | ssh student@44.44.44.2
echo "sudo mkdir -p /root/.ssh" | ssh student@55.55.55.2

echo "sudo cp id /root/.ssh/authorized_keys" | ssh student@11.11.11.2
echo "sudo cp id /root/.ssh/authorized_keys" | ssh student@22.22.22.2
echo "sudo cp id /root/.ssh/authorized_keys" | ssh student@44.44.44.2
echo "sudo cp id /root/.ssh/authorized_keys" | ssh student@55.55.55.2

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

# Переход на HQ-SRV

ssh root@11.11.11.2 -p 2222

# Переименование хостов

hostnamectl hostname hq.work.hq-srv
domainname hq.work

# Установка утилит и выход из устройства

apt-get install samba-dc -y
apt-get install bind-utils -y
exit

# Вход в HQ-RTR

ssh root@22.22.22.2

# Изменение файла dhcpd.conf

cat << EOF > /etc/dhcp/dhcpd.conf

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

