# DEMO-2024-TESTING
Another testing style. For automatisation.

# Требования для активации автоматизации:

## BR-RTR | HQ-RTR | CLI

- Базовая коммутация до ISP-a (Чтобы IP-адреса были скоммутированны изначально)
- Предписание resolv.conf именно в /etc/net/ifaces/ens/resolv.conf (По какой-то причине оно более стабильно работает именно так)
- Добавление юзера в gpasswd для получения root-прав

## BR-SRV | HQ-SRV 

- Базовая коммутация до RTR
- Предписание resolv.conf именно в /etc/net/ifaces/ens/resolv.conf (Такая же причина.)
- Добавление юзера в gpasswd для получения root-прав

## Команда для активации на ISP:

```bash
apt-get update && apt-get install git && git clone https://github.com/NiKeNO1540/DEMO-2024-TESTING && mv DEMO-2024-TESTING/isp_part_1.sh isp_1_copy.sh

do
> echo "#! /bin/bash" > isp_1.sh
> cat isp_1_copy.sh >> isp_1.sh
> chmod +x isp_1.sh
> ./isp_1.sh
> done
```
