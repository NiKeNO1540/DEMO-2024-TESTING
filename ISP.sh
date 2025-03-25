# Установка имени хоста
hostnamectl set-hostname ISP

# Создание директорий для сетевых интерфейсов
mkdir -p /etc/net/ifaces/ens224
mkdir -p /etc/net/ifaces/ens256

# Настройка опций интерфейса ens161
cat << EOF > /etc/net/ifaces/ens161/options
TYPE=eth
BOOTPROTO=static
CONFIG_IPV4=yes
DISABLED=no
EOF

# Копирование опций на другие интерфейсы
cp /etc/net/ifaces/ens161/options /etc/net/ifaces/ens224/options
cp /etc/net/ifaces/ens161/options /etc/net/ifaces/ens256/options

# Настройка IP-адресов
echo "22.22.22.1/30" > /etc/net/ifaces/ens224/ipv4address
echo "33.33.33.1/24" > /etc/net/ifaces/ens256/ipv4address
echo "44.44.44.1/30" > /etc/net/ifaces/ens161/ipv4address

# Включение IP-форвардинга
echo "net.ipv4.ip_forward = 1" >> /etc/net/sysctl.conf
sysctl -p

# Настройка NAT
iptables -t nat -A POSTROUTING -o ens192 -s 0/0 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
systemctl enable --now iptables.service

# Обновление системы
apt-get update && apt-get dist-upgrade -y

# Установка и настройка FRR для OSPF
apt-get install frr -y
sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons
systemctl enable --now frr.service

# Настройка OSPF через vtysh
cat << EOF | vtysh
conf t
router ospf
network 44.44.44.0/30 area 0
network 22.22.22.0/30 area 0
network 192.168.88.0/24 area 0
do wr
end
exit
EOF

systemctl restart frr

# Установка iperf3 для измерения пропускной способности
apt-get install iperf3 -y
iperf3 -s &

# Перезагрузка для применения изменений
reboot
