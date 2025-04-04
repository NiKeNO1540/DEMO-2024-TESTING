#! /bin/bash

# Генерация ключей + выдача их + сканирование отпечатков (НИКОГДА ТАК НЕ ДЕЛАЕТЕ НА РЕАЛЬНОМ ОБОРУДОВАНИИ, ТАК КАК ЭТО ЛОГИРУЕТСЯ И ЗЛОУМЫШЛЕННИК ПОЛУЧИТ ДОСТУП К ВАШЕЙ СЕТИ, ЗДЕСЬ ОНО СДЕЛАНО В РАМКАХ АВТОМАТИЗАЦИИ)

ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
ssh-keyscan -H 44.44.44.2 >> ~/.ssh/known_hosts
apt-get install sshpass
sshpass -p 'P@ssw0rd' ssh-copy-id student@44.44.44.2
ssh-keyscan -H 22.22.22.2 >> ~/.ssh/known_hosts
sshpass -p 'P@ssw0rd' ssh-copy-id student@22.22.22.2

# Добавление resolv конфига через ssh.

cat << EOF > nameserver.sh
#! /bin/bash
echo Starting on $(hostname)

echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo Ended
EOF

scp nameserver.sh student@44.44.44.2:/home/student/nameserver.sh
scp nameserver.sh student@22.22.22.2:/home/student/nameserver.sh

echo "sudo chmod +x nameserver.sh" | ssh student@44.44.44.2
echo "sudo chmod +x nameserver.sh" | ssh student@22.22.22.2

echo "sudo ./nameserver.sh" | ssh student@44.44.44.2
echo "sudo ./nameserver.sh" | ssh student@22.22.22.2

# Обновление пакетов.

echo "sudo apt-get update" | ssh student@44.44.44.2
echo "sudo apt-get update" | ssh student@22.22.22.2

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
   ansible_user: student
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
cp /root/DEMO-2024-TESTING/HQ-SRV.yml /root/HQ-SRV.yml
ansible-playbook HQ-SRV.yml
cp /root/DEMO-2024-TESTING/CLI.yml /root/CLI.yml
ansible-playbook CLI.yml
