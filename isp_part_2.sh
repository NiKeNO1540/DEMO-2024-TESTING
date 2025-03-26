# Прикольная фича с ключами + раздача на спавне

ssh-keygen -t rsa
echo -e "yes\nP@ssw0rd" ssh-copy-id branch_admin@44.44.44.2

# Магия вне хогвартса (Обновление пакетов через ssh на BR-RTR)

echo "sudo apt-get update" | ssh branch_admin@44.44.44.2

# Установка ansible

apt-get install ansible -y

# Настройка хостов

cat << EOF > /etc/ansible/hosts
VMs:
 hosts:
  BR-RTR:
   ansible_host: 44.44.44.2
   ansible_user: branch_admin
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
