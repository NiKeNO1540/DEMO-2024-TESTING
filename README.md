# DEMO-2024-TESTING
Another testing style. For automatisation.

---

# Преднастройка:

### ESXI

- Добавление временного подключения между CLI и HQ-SRV

#### Инструкция

Зайди на адрес своего ESXI, пароль будет P@ssw0rd. Зайди в Networking > Add Port Group Далее как на скринах.

![image](https://github.com/user-attachments/assets/af597374-9169-4069-82ff-92105bc9c960)

Затем зайди в Virtual Machines, и добавить на CLI и HQ-SRV новое подключение путем ПКМ на них > Edit Settings, как на скрине.

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
# Пишите 123, потом Shift+G > Стрелка вправо > Нажать "D" затем стрелка вправо > :wq
gpasswd -a "student" wheel
```

- (CLI ONLY) Разрешение вход под root через ssh (неизвестно, но на этой машине нету команды sudo)

#### CLI
```bash
vim /etc/openssh/sshd_config
# 32-ая строка(Нажать 32, затем Shift+G) > Убрать решетку и заменить without-password на yes
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
echo 55.55.55.2/28 > /etc/net/ifaces/ens192/ipv4address
echo default via 55.55.55.1 > /etc/net/ifaces/ens192/ipv4route
systemctl restart network
```

- Добавление пользователя student в группу wheel и уравнение прав на уровне root-a

#### HQ-SRV | BR-SRV

```bash
visudo
# Пишите 123G > Стрелка вправо > Нажать "D" затем стрелка вправо > :wq
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

---

# Команды после автоматизации

### CLI

После установки перезапустить компьютер. Затем войти под administrator с паролем P@ssw0rd.

Затем открыть браузер Firefox и открыть две вкладки. На одной вкладке вписать http://moodle.hq-srv.hq.work, на второй 11.11.11.2:8080

#### Первая вкладка (Moodle)

![image](https://github.com/user-attachments/assets/9259389f-9de7-4f6e-81ff-9920fdaac47e)
![image](https://github.com/user-attachments/assets/ba58b059-2d8d-4d1d-80a1-2492d6ed0d42)
![image](https://github.com/user-attachments/assets/18c9c353-5831-4178-b305-777e34fb09e2)
![image](https://github.com/user-attachments/assets/66084423-6c8d-4a4b-a4e0-ea58b33b82d7)
![image](https://github.com/user-attachments/assets/9713bebe-7159-4413-a0af-9c3750dd0467)
![image](https://github.com/user-attachments/assets/7e8e52c6-27f3-460a-b291-1d66ce9f5310)
![image](https://github.com/user-attachments/assets/048fb504-ef32-45d9-831e-1534c8137a55)
![image](https://github.com/user-attachments/assets/b30c82eb-4564-4b1f-a0ab-f118dec7ed3a)
![image](https://github.com/user-attachments/assets/c58d5b9e-456a-4fc3-8c83-008e5c7bf1e1)
![image](https://github.com/user-attachments/assets/82943536-c001-4216-8f8d-52dafbac5821)
![image](https://github.com/user-attachments/assets/b819ad3b-39d3-446a-82cf-b0c280c0f241)
![image](https://github.com/user-attachments/assets/8605dd0f-2067-4a57-a91a-79c213254da6)
![image](https://github.com/user-attachments/assets/d1ad4a3b-de8c-48aa-80db-a608bc1522fe)
![image](https://github.com/user-attachments/assets/6168f965-17f0-4894-96e3-0e13bd6ef9a9)
![image](https://github.com/user-attachments/assets/b428c0ca-2d30-48cf-babf-c34d6fa8a945)
![image](https://github.com/user-attachments/assets/741e15d2-0c18-4eaf-8feb-93182f958fd4)
![image](https://github.com/user-attachments/assets/8c79ae3b-230e-4f8d-b515-c11da83ed18b)
![image](https://github.com/user-attachments/assets/bc762365-999e-4679-af12-0257527342cc)
![image](https://github.com/user-attachments/assets/43791251-3e01-425d-a77d-49cdef114dbc)
![image](https://github.com/user-attachments/assets/35bc0673-fd45-40ca-86a8-82c26d73e5c9)
![image](https://github.com/user-attachments/assets/f21239a1-4b0a-4e4d-9b98-94e3823f95f0)
![image](https://github.com/user-attachments/assets/99a2bb33-d024-465a-a9ff-0c35762307c0)
![image](https://github.com/user-attachments/assets/1835f84d-252e-4f12-89d8-3887b9cb85eb)
![image](https://github.com/user-attachments/assets/3433276a-f027-45a4-af62-5c636aece5bc)
![image](https://github.com/user-attachments/assets/2f00e52c-dd91-4848-a127-1a667c59f87f)
![image](https://github.com/user-attachments/assets/1fa94e25-4cf0-4a22-9710-ca3dd9b15710)
![image](https://github.com/user-attachments/assets/3f8aa51a-7d03-419c-8942-3882b9a0710e)

#### Вторая вкладка (Mediawiki)

![image](https://github.com/user-attachments/assets/e922a82f-1a77-4a80-accd-67f43789a588)
![image](https://github.com/user-attachments/assets/3cf78957-a007-4574-bc03-10bd26d789ae)
![image](https://github.com/user-attachments/assets/ea61ea18-87b7-4a0f-b840-1facc0498e5b)
![image](https://github.com/user-attachments/assets/eaa4fcdc-d344-431b-b26e-baa27c7d0cd4)
![image](https://github.com/user-attachments/assets/4387ea44-f6e1-43af-a107-515e932056d9)
![image](https://github.com/user-attachments/assets/3879e8e9-92c7-43f0-ad53-41a758c6b77f)
![image](https://github.com/user-attachments/assets/c8abebdf-59a5-4250-bc5b-3dd2f5b4fd6b)
![image](https://github.com/user-attachments/assets/2f904e16-bdce-427c-9e9e-5790f37d222e)
![image](https://github.com/user-attachments/assets/45d7323e-d858-4d11-a0d4-0ece55d3ee1d)
![image](https://github.com/user-attachments/assets/66b7b8c6-d0a9-4286-a5a9-55c826e7b940)

После того, как вам скачался файл LocalSettings.php

#### CLI

```bash
scp -P 2222 /home/HQ.WORK/administrator/Загрузки/LocalSettings.php student@11.11.11.2:/home/student/
# Пароль: P@ssw0rd
```

####

HQ-SRV
```bash
mv /home/student/LocalSettings.php ~/
docker compose -f wiki.yml stop && docker compose -f wiki.yml up -d
```
