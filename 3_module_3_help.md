# Как запустить fail2ban:

## 1. Установка утилит:

> Помимо fail2ban, нужно ещё установить python3-module-systemd, чтобы можно было дальше пользоваться всеми возможностями.

`apt-get install fail2ban python3-module-systemd -y`

Объяснение: без второго пакета не получиться пользоваться логированием НЕ через файлы

## 2. Настройка

> Открываем через `vim /etc/fail2ban/jail.d/sshd.local` и прописываем:
```tcl
[DEFAULT]
bantime = 60
findtime = 600
[sshd]
enabled = true
port = 2026
filter = sshd
maxretry = 3
backend = systemd
```
`maxretry = 3` — количество действий, которые разрешено совершить до бана, по заданию 3.

`findtime = 600` — время в секундах, в течение которого учитывается maxretry;

`bantime = 60` — время, на которое будет блокироваться IP-адрес, по заданию минута;

`[sshd]` — название для правила;

`enabled = true` позволяет быстро включать (true) или отключать (false) правило;

`port = 2026` — порт целевого сервиса. Принимается буквенное или цифирное обозначение;

`filter = sshd` — фильтр (критерий поиска), который будет использоваться для поиска подозрительных действий. По сути, это имя файла из каталога /etc/fail2ban/filter.d без .conf на конце;

`backend = systemd` - Строка, которая отвечает за то, что он будет считывать логи не с ФАЙЛА, а с журнала systemd, так как в более новых версиях Linux лог хранится не в файлах а базе systemd.

## 3. Запуск и проверка

> Запускаем fail2ban если не делали или перезапускаем или то и то другое.

`systemctl enable --now fail2ban && systemctl restart fail2ban`

> Затем проверяем

`fail2ban-client status`

<img width="444" height="71" alt="image" src="https://github.com/user-attachments/assets/03146c31-d212-4456-8dde-fab5f6e448c5" />

> Затем на любой машине ПЫТАЕМСЯ войти, вводя не правильные пароли (Условно на ISP-e через `ssh sshuser@172.16.1.4 -p 2026`)

<img width="764" height="127" alt="image" src="https://github.com/user-attachments/assets/2d4bc05f-eefe-431e-865f-c1c4e533b290" />

> После неудачных попыток нас выкидывает, не давая возможности на минуту повторно зайти, попутно у HQ-SRV при вводе `iptables -L` выводится следующее:

<img width="865" height="78" alt="image" src="https://github.com/user-attachments/assets/77b9a458-0cdb-411e-b6f6-302015a11658" />

> Через минуту должно пропасть.

<img width="553" height="56" alt="image" src="https://github.com/user-attachments/assets/c6ea1742-da22-4e73-881f-633af7b7d4de" />

> Если нужно удоствериться, что прошла одна минута, загляните в /var/log/fail2ban.log

<img width="788" height="58" alt="image" src="https://github.com/user-attachments/assets/30207c51-cd93-4274-81a6-231885689941" />



