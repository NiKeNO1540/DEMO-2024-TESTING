# DEMO-2024-TESTING
Another testing style. For automatisation.

---

# Преднастройка:

### ESXI

- Добавление временного подключения между CLI и HQ-SRV

#### Инструкция

Зайди на адрес своего ESXI, пароль будет P@ssw0rd. Далее как на скринах.

![image](https://github.com/user-attachments/assets/af597374-9169-4069-82ff-92105bc9c960)
![image](https://github.com/user-attachments/assets/8904125b-74a7-446a-b352-5223bcf9e44d)


### BR-RTR | HQ-RTR | CLI

- Базовая коммутация до ISP-a (Чтобы IP-адреса были заданы изначально):

#### HQ-RTR

```bash
mkdir /etc/net/ifaces/ens224
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens192/options
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens224/options
echo 11.11.11.1/26 > /etc/net/ifaces/ens192/ipv4address
echo 22.22.22.2/30 > /etc/net/ifaces/ens224/ipv4address
echo default via 22.22.22.1 > /etc/net/ifaces/ens224/ipv4route
systemctl restart network
```

#### BR-RTR
```bash
mkdir /etc/net/ifaces/ens224
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens192/options
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens224/options
echo 44.44.44.2/30 > /etc/net/ifaces/ens192/ipv4address
echo default via 44.44.44.1 > /etc/net/ifaces/ens192/ipv4route
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
echo -e "BOOTPROTO=static\nTYPE=eth\nNM_CONTROLLED=no\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens192/options
systemctl restart network
```

- Добавление пользователя student в группу wheel и уравнение прав на уровне root-a

#### HQ-RTR | BR-RTR
```bash
visudo
# Пишите 123G > Стрелка влево > Нажать "D" затем стрелка вправо > :wq
gpasswd -a "student" wheel
```

- (CLI ONLY) Разрешение вход под root через ssh (неизвестно, но на этой машине нету команды sudo)

#### CLI
```bash
vim /etc/openssh/sshd_config
# 32-ая строка > Убрать решетку и заменить without-password на yes
:wq
systemctl enable --now sshd
reboot
```

### BR-SRV | HQ-SRV 

- Базовая коммутация до RTR:

#### HQ-SRV
```bash
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens192/options
echo 11.11.11.2/26 > /etc/net/ifaces/ens192/ipv4address
echo default via 11.11.11.1 > /etc/net/ifaces/ens192/ipv4route
systemctl restart network
```

#### BR-SRV
```bash
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens192/options
echo 55.55.55.2/26 > /etc/net/ifaces/ens192/ipv4address
echo default via 55.55.55.1 > /etc/net/ifaces/ens192/ipv4route
systemctl restart network
```

- Добавление пользователя student в группу wheel и уравнение прав на уровне root-a

#### HQ-SRV | BR-SRV

```bash
visudo
# Пишите 123G > Стрелка влево > Нажать "D" затем стрелка вправо > :wq
gpasswd -a "student" wheel
```

# Причины преднастройки

## 1 часть: Базовая коммутация до ISP-a | RTR-a

Причина в том, что на всех устройствах кроме ISP-a не имеется доступ к интернету, и даже не только это, основная причина в том, что у всех файлов конфигурации на устройствах по умолчанию стоит **СТАТИЧЕСКАЯ** маршрутизация, которая и ставит палки в колеса. Было бы изменено на DHCP-Запросы изначально, тогда можно было технически сделать полную автоматизацию, используя Технологию WoL (Wake-on-LAN) и DHCP-адресацию через **ISP.** А теперь немного поговорим про сами определения.

### Что такое Wake-on-Lan

**Wake-on-LAN (WOL; в переводе с англ. — «пробуждение по [сигналу из] локальной сети») — технология, позволяющая удалённо включить компьютер посредством отправки через локальную сеть специальной последовательности байтов.** если объяснять как оно работает: то с одного устройства прилетает "магический пакет" по сетевому кабелю, который в свою очередь и дает возможность **УДАЛЕННО** запускать устройства, главным условием нужно чтобы были в одной сети или имели возможность через какое-то устройство пробудить его.


# Инструкция для активации на ISP:

```bash
apt-get update && apt-get install git -y && git clone https://github.com/NiKeNO1540/DEMO-2024-TESTING && chmod +x DEMO-2024-TESTING/isp_part_1_test.sh && ./DEMO-2024-TESTING/isp_part_1_test.sh
```
