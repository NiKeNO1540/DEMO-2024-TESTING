# DEMO-2024-TESTING
Another testing style. For automatisation.

# Требования для активации автоматизации:

## BR-RTR | HQ-RTR | CLI

- Базовая коммутация до ISP-a (Чтобы IP-адреса были скоммутированны изначально)
- Предписание resolv.conf: nameserver 8.8.8.8
- Добавление юзера в gpasswd для получения root-прав

## BR-SRV | HQ-SRV 

- Базовая коммутация до RTR
- Предписание resolv.conf: nameserver 8.8.8.8
- Добавление юзера в gpasswd для получения root-прав

## Инструкция для активации на ISP:

```bash
1. bash apt-get update && apt-get install git && git clone https://github.com/NiKeNO1540/DEMO-2024-TESTING && mv DEMO-2024-TESTING/isp_part_1.sh isp_1_copy.sh ```
2. echo "#! /bin/bash" > isp_1.sh && vim isp_1_copy.sh
> y500y
> :q
vim isp_1.sh
> p
> :wq
chmod +x isp_1.sh
./isp_1.sh
```
