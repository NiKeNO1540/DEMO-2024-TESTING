# DEMO-2024-TESTING
Another testing style. For automatisation.

# Преднастройка:

### BR-RTR | HQ-RTR | CLI

- Базовая коммутация до ISP-a (Чтобы IP-адреса были заданы изначально):

#### HQ-RTR

```bash
mkdir /etc/net/ifaces/ens224
echo 11.11.11.1/26 > /etc/net/ifaces/ens192/ipv4address
cp /etc/net/ifaces/ens192/options /etc/net/ifaces/ens224/options
echo 22.22.22.1/30 > /etc/net/ifaces/ens224/ipv4address
echo default via 22.22.22.1 > /etc/net/ifaces/ens224/ipv4route
systemctl restart network
```

#### BR-RTR
```bash
mkdir /etc/net/ifaces/ens224
echo 44.44.44.2/30 > /etc/net/ifaces/ens192/ipv4address
echo default via 44.44.44.1 > /etc/net/ifaces/ens192/ipv4route
cp /etc/net/ifaces/ens192/options /etc/net/ifaces/ens224/options
echo 55.55.55.1/28 > /etc/net/ifaces/ens224/ipv4address
systemctl restart network
```

#### CLI
```bash
# Открывайте терминал через ПКМ по рабочему столу > Терминал

su -
# Пароль: P@ssw0rd
echo 33.33.33.2/24 > /etc/net/ifaces/ens192/ipv4address
echo default via 33.33.33.1 > /etc/net/ifaces/ens192/ipv4route
sed -i "s/DISABLED
```

- Добавление пользователя student в группу wheel и уравнение прав на уровне root-a
- (CLI ONLY) Разрешение вход под root через ssh (неизвестно, но на этой машине нету команды sudo)

### BR-SRV | HQ-SRV 

- Базовая коммутация до RTR
- Добавление пользователя student в группу wheel и уравнение прав на уровне root-a

# Причины преднастройки

## 1 часть: Базовая коммутация до ISP-a | RTR-a

Причина в том, что на всех устройствах кроме ISP-a не имеется доступ к интернету, и даже не только это, основная причина в том, что у всех файлов конфигурации на устройствах по умолчанию стоит **СТАТИЧЕСКАЯ** маршрутизация, которая и ставит палки в колеса. Было бы изменено на DHCP-Запросы изначально, тогда можно было технически сделать полную автоматизацию, используя Технологию WoL (Wake-on-LAN) и DHCP-адресацию через **ISP.** А теперь немного поговорим про сами определения.

### Что такое Wake-on-Lan

**Wake-on-LAN (WOL; в переводе с англ. — «пробуждение по [сигналу из] локальной сети») — технология, позволяющая удалённо включить компьютер посредством отправки через локальную сеть специальной последовательности байтов.** если объяснять как оно работает: то с одного устройства прилетает "магический пакет" по сетевому кабелю, который в свою очередь и дает возможность **УДАЛЕННО** запускать устройства, главным условием нужно чтобы были в одной сети или имели возможность через какое-то устройство пробудить его.


# Инструкция для активации на ISP:

```bash
apt-get update && apt-get install git -y && git clone https://github.com/NiKeNO1540/DEMO-2024-TESTING && chmod +x DEMO-2024-TESTING/isp_part_1_test.sh && ./DEMO-2024-TESTING/isp_part_1_test.sh
```
