CoWFC Installer
======

This script installs the CoWFC front-end and back-end from https://github.com/EnergyCube/CoWFC

✅ Support Ubuntu 22.04 (& 20.04 AWS)


✅ Support Debian 10 (❌ LAN Reported not working ! Only tested on a VPS using a domain name)

🔨 Contributing
-------

Please open pull requests.

🔧 Error reporting
-------

Create a new issue and communicate all informations that you can.

📝 How to use
-------

![image](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Ubuntu_logo.svg/100px-Ubuntu_logo.svg.png)

`mkdir /var/www ; cd /var/www && wget https://raw.githubusercontent.com/jeffabenr/cowfc_installer/master/cowfc.sh && chmod +x cowfc.sh && ./cowfc.sh`

After system reboot : `cd /var/www && ./cowfc.sh`

Replace cowfc.sh with cowfc_for_aws_ubuntu_16.sh if you are using AWS.

Criar Usuário web

chmod +x criar_usuario.sh && ./criar_usuario.sh


![image](https://www.debian.org/logos/openlogo-nd-25.png) Debian
----

`wget https://raw.githubusercontent.com/mwaddip/cowfc_installer/master/cowfc-debian.sh && chmod +x cowfc-debian.sh && ./cowfc-debian.sh`

📖 Notes
-------

This script comes in 3 phases for Ubuntu. Each phase involves a reboot
-	Add the PHP 7.4 repo
-	Install required packages
-	CoWFC install
-	Reboot after CoWFC install

This script comes in 1 phases for Debian.
-	Install CoWFC & Reboot

Ubuntu script use PHP 7.4 & MySQL\
Debian script use PHP 7.4 & MariaDB\
AWS Ubuntu 16.04 script use PHP 7.0 & MySQL

Solução de Problemas
ubuntu 22.04
a porta do systemd-resolved usando a mesma porta do dnsmasq ou faltando systemd-resolved para iniciar o dnsmasq
basta trocar a porta do systemd-resolved para resolver o problema definitivamente
Comando
$sudo nano /etc/systemd/resolved.conf
DNS=1.1.1.1
DNSStubListener=no
$sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
e reiniciar
link da solução
https://linuxavante.com/ubuntu-como-liberar-a-porta-53-usada-por-systemd-resolvido

❤️ Credits
-------
kyle95wm\
EnergyCube
