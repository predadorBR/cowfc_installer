#!/bin/bash
echo "########## !!!!! WARNING !!!!! ##########"
echo "Recently, Wiimmfi has undergone some changes which makes it so that their servers are more secure from hackers."
echo "Having said that, this means that the CoWFC fork will not be getting the security patch, as it is unclear how it is possible. For the time being, you accept that you run your own server with a chance that hackers will be able to execute code over the MKW network."
echo "This might mean that hackers can in theory, brick consoles."
# DWC Network Installer script by kyle95wm/beanjr/EnergyCube - re-written for CoWFC
# Warn Raspberry Pi users - probably a better way of doing this
if [ -d /home/pi/ ]; then
    echo "THIS SCRIPT IS NOT SUPPORTED ON RASPBERRY PI!"
    echo "Please use the older script here: https://github.com/predadorBR/dwc_network_installer"
    exit 1
fi
# Check if we already installed the server
if [ -f /etc/.dwc_installed ]; then
    echo "You already installed CoWFC. There is no need to re-run it.
Perhaps some time down the road we can offer an uninstall option.
You shouldn't have anything else on it anyways."
    echo "If you only want to RESET your dwc server, just delete gpcm.db and storage.db (don't forget to reboot of course)"
    echo "In you want to UPDATE your actual installation, the best way is to save gpcm.db and storage.db (in dwc_network_server_emulator),
nuke your system, re-install everything with this script and restore gpcm.db and storage.db"
    echo "And if you wish to uninstall everything, just nuke your system."
    #exit 999
fi
# ensure running as root
if [ "$(id -u)" != "0" ]; then
    exec sudo "$0" "$@"
fi

# We will test internet connectivity using ping
if ping -c 2 github.com >/dev/null; then
    echo "Internet is OK"
elif ping -c 2 torproject.org >/dev/null; then
    echo "Internet is OK"
else
    echo "Internet Connection Test Failed!"
    echo "If you want to bypass internet check use -s arg!"
    exit 1
fi

# We'll assume the user is from an English locale
if [ ! -f /var/www/.locale-done ]; then
    if ! locale-gen en_US.UTF-8; then
        apt install -y language-pack-en-base
    fi
fi
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# We'll create our secret locale file
touch /var/www/.locale-done

# Variables used by the script in various sections to pre-fill long commandds
C1="0"            # A counting variable
C2="0"            # A counting variable
IP=""             # Used for user input
interface=""      # Used for user input
mod1="proxy"      # This is a proxy mod that is dependent on the other 2
mod2="proxy_http" # This is related to mod1
mod3="php8.3"
UPDATE_FILE="$0.tmp"
UPDATE_BASE="https://raw.githubusercontent.com/predadorBR/cowfc_installer/master/cowfc.sh"
# Functions

function update() {
    # The following lines will check for an update to this script if the -s switch
    # is not used.

    # Original code by Dennis Simpson
    # Modified by Kyle Warwick-Mathieu
    echo "Checking if script is up to date, please wait"
    wget -nv -O "$UPDATE_FILE" "$UPDATE_BASE" >&/dev/null
    if ! diff "$0" "$UPDATE_FILE" >&/dev/null && [ -s "$UPDATE_FILE" ]; then
        mv "$UPDATE_FILE" "$0"
        chmod +x "$0"
        echo "$0 updated"
        "$0" -s
        exit
    else
        rm "$UPDATE_FILE" # If no updates are available, simply remove the file
    fi
}

function create_apache_vh_nintendo() {
    # This function will create virtual hosts for Nintendo's domains in Apache
    echo "Creating Nintendo virtual hosts...."
    touch /etc/apache2/sites-available/gamestats2.gs.nintendowifi.net.conf
    touch /etc/apache2/sites-available/gamestats.gs.nintendowifi.net.conf
    touch /etc/apache2/sites-available/nas-naswii-dls1-conntest.nintendowifi.net.conf
    touch /etc/apache2/sites-available/sake.gs.nintendowifi.net.conf
    cat >/etc/apache2/sites-available/gamestats2.gs.nintendowifi.net.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
ServerName gamestats2.gs.nintendowifi.net
ServerAlias "gamestats2.gs.nintendowifi.net, gamestats2.gs.nintendowifi.net"
ProxyPreserveHost On
ProxyPass / http://127.0.0.1:9002/
ProxyPassReverse / http://127.0.0.1:9002/
</VirtualHost>
EOF

    cat >/etc/apache2/sites-available/gamestats.gs.nintendowifi.net.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
ServerName gamestats.gs.nintendowifi.net
ServerAlias "gamestats.gs.nintendowifi.net, gamestats.gs.nintendowifi.net"
ProxyPreserveHost On
ProxyPass / http://127.0.0.1:9002/
ProxyPassReverse / http://127.0.0.1:9002/
</VirtualHost>
EOF

    cat >/etc/apache2/sites-available/nas-naswii-dls1-conntest.nintendowifi.net.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
ServerName naswii.nintendowifi.net
ServerAlias "naswii.nintendowifi.net, naswii.nintendowifi.net"
ServerAlias "nas.nintendowifi.net"
ServerAlias "nas.nintendowifi.net, nas.nintendowifi.net"
ServerAlias "dls1.nintendowifi.net"
ServerAlias "dls1.nintendowifi.net, dls1.nintendowifi.net"
ServerAlias "conntest.nintendowifi.net"
ServerAlias "conntest.nintendowifi.net, conntest.nintendowifi.net"
ProxyPreserveHost On
ProxyPass / http://127.0.0.1:9000/
ProxyPassReverse / http://127.0.0.1:9000/
</VirtualHost>
EOF

    cat >/etc/apache2/sites-available/sake.gs.nintendowifi.net.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
ServerName sake.gs.nintendowifi.net
ServerAlias sake.gs.nintendowifi.net *.sake.gs.nintendowifi.net
ServerAlias secure.sake.gs.nintendowifi.net
ServerAlias secure.sake.gs.nintendowifi.net *.secure.sake.gs.nintendowifi.net
ProxyPass / http://127.0.0.1:8000/
CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

    echo "Done!"
    echo "enabling...."
    a2ensite *.nintendowifi.net.conf
    service apache2 restart
}

function create_apache_vh_wiimmfi() {
    # This function will create virtual hosts for Wiimmfi's domains in Apache
    echo "Creating Wiimmfi virtual hosts...."
    touch /etc/apache2/sites-available/gamestats2.gs.wiimmfi.de.conf
    touch /etc/apache2/sites-available/gamestats.gs.wiimmfi.de.conf
    touch /etc/apache2/sites-available/nas-naswii-dls1-conntest.wiimmfi.de.conf
    touch /etc/apache2/sites-available/sake.gs.wiimmfi.de.conf
    cat >/etc/apache2/sites-available/gamestats2.gs.wiimmfi.de.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
ServerName gamestats2.gs.wiimmfi.de
ServerAlias "gamestats2.gs.wiimmfi.de, gamestats2.gs.wiimmfi.de"
ProxyPreserveHost On
ProxyPass / http://127.0.0.1:9002/
ProxyPassReverse / http://127.0.0.1:9002/
</VirtualHost>
EOF

    cat >/etc/apache2/sites-available/gamestats.gs.wiimmfi.de.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
ServerName gamestats.gs.wiimmfi.de
ServerAlias "gamestats.gs.wiimmfi.de, gamestats.gs.wiimmfi.de"
ProxyPreserveHost On
ProxyPass / http://127.0.0.1:9002/
ProxyPassReverse / http://127.0.0.1:9002/
</VirtualHost>
EOF

    cat >/etc/apache2/sites-available/nas-naswii-dls1-conntest.wiimmfi.de.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
ServerName naswii.wiimmfi.de
ServerAlias "naswii.wiimmfi.de, naswii.wiimmfi.de"
ServerAlias "nas.wiimmfi.de"
ServerAlias "nas.wiimmfi.de, nas.wiimmfi.de"
ServerAlias "dls1.wiimmfi.de"
ServerAlias "dls1.wiimmfi.de, dls1.wiimmfi.de"
ServerAlias "conntest.wiimmfi.de"
ServerAlias "conntest.wiimmfi.de, conntest.wiimmfi.de"
ProxyPreserveHost On
ProxyPass / http://127.0.0.1:9000/
ProxyPassReverse / http://127.0.0.1:9000/
</VirtualHost>
EOF

    cat >/etc/apache2/sites-available/sake.gs.wiimmfi.de.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
ServerName sake.gs.wiimmfi.de
ServerAlias sake.gs.wiimmfi.de *.sake.gs.wiimmfi.de
ServerAlias secure.sake.gs.wiimmfi.de
ServerAlias secure.sake.gs.wiimmfi.de *.secure.sake.gs.wiimmfi.de
ProxyPass / http://127.0.0.1:8000/
CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

    echo "Done!"
    echo "enabling...."
    a2ensite *.wiimmfi.de.conf
    service apache2 restart
}
function apache_mods() {
    a2enmod $mod1 $mod2
    service apache2 restart
    if ! a2enmod $mod3; then
        a2dismod mpm_event
        a2enmod $mod3
        service apache2 restart
    fi
    service apache2 restart
}

function dns_config() {
    # This function will configure dnsmasq
    echo "----------Lets configure DNSMASQ now----------"
    sleep 3s
    # The snippet below will create what's known as an open resolver.
    # Having an open resolver is a security risk and is not a good idea.
    # As it would break the script to disable it from the start, it's enabled
    # only temporarily and disabled after the script is finished.
    # It means that DNS will be restricted to ONLY looking up Nintendo domains.
    echo "Temporarily adding Google DNS (8.8.8.8) to config"
    # We add Google's DNS server to our server so that anyone with our DNS server can still resolve hostnames to IP
    # addresses outside our DNS server. Useful for Dolphin testing
    cat >>/etc/dnsmasq.conf <<EOF
server=8.8.8.8
EOF
    #sleep 2s
    echo "What is your EXTERNAL IP?"
    echo "NOTE: If you plan on using this on a LAN, put the IP of your Linux system instead"
    echo "It's also best practice to make this address static in your /etc/network/interfaces file"
    echo "Your LAN IP is"
    hostname -I | cut -f1 -d' '
    echo "Your external IP is:"
    curl -4 -s icanhazip.com
    echo "Please type in either your LAN or external IP"
    read -re IP
    cat >>/etc/dnsmasq.conf <<EOF # Adds your IP you provide to the end of the DNSMASQ config file
address=/nintendowifi.net/$IP
address=/wiimmfi.de/$IP
EOF
    clear
    ifconfig
    read -rp "Please type your primary interfaces's name (e.g - eth0): " interface
    cat >>/etc/dnsmasq.conf <<EOF
interface="$interface"
EOF
    clear
    echo "DNSMasq setup completed!"
    clear
    service dnsmasq restart
    touch "/var/www/.dnsmasq-added"
    clear
}

function install_required_packages() {
  echo "echo "Installing required packages...""
    # Add required package requires packages
    sudo apt install curl git net-tools dnsmasq -y
    # Add PHP 8.3 repo
    if [ ! -f "/var/www/.php83-added" ]; then
        echo "Adding the PHP 8.3 repository. Please follow any prompts."
        if ! add-apt-repository ppa:ondrej/php; then
            apt install  software-properties-common python-software-properties -y
            add-apt-repository ppa:ondrej/php
        fi
        sleep 2s
        echo "Creating file to tell the script you already added the repo"
        touch "/var/www/.php83-added"
        echo "I will now reboot your server to free up resources for the next phase"
        sleep 3s
        reboot
        exit
    else
        echo "The PHP 8.3 repo is already added. If you believe this to ben an error, please type 'rm -rf /var/www/.php83-added' to remove the file which prevents the repository from being added again."
    fi
    # Fix dpkg problems that happened somehow
    dpkg --configure -a
    echo "Updating & installing PHP 8.3 onto your system..."
    apt update
    # Install the other required packages
    apt install -y apache2 php8.3 php8.3-mysql php8.3-sqlite3 sqlite python2.7 python2.7-dev -y && curl -O https://bootstrap.pypa.io/pip/2.7/get-pip.py && python2.7 get-pip.py && pip install twisted
    ln -s /usr/bin/python2.7 /usr/bin/python
  
    #if [ -f /etc/lsb-release ]; then
     # if grep -q "24.04" /etc/lsb-release; then
        #systemctl disable systemd-resolved.service
        # systemctl stop systemd-resolved.service
	#systemctl start dnsmasq.service
     # fi
   # fi

}
function config_mysql() {
    echo "We will now configure MYSQL server."
    debconf-set-selections <<<'mysql-server mysql-server/root_password password passwordhere'
    debconf-set-selections <<<'mysql-server mysql-server/root_password_again password passwordhere'
    apt -y install mysql-server
    # We will now set the new mysql password in the AdminPage.php file.
    # Do not change "passwordhere", as this will be the base for replacing it later
    # The below sed command has NOT been tested so we don't know if this will work or not.
    #sed -i -e 's/passwordhere/passwordhere/g' /var/www/html/_site/AdminPage.php
    # Now we will set up our first admin user
    echo "Now we're going to set up our first Admin Portal user."
    read -rp "Please enter the username you wish to use: " firstuser
    read -rp "Please enter a password: " password
    hash=$(/var/www/CoWFC/SQL/bcrypt-hash "$password")
    echo "We will now set the rank for $firstuser"
    echo "At the moment, this does nothing. However in later releases, we plan to restrict who can do what."
    echo "1: First Rank"
    echo "2: Second Rank"
    echo "3: Third Rank"
    read -rp "Please enter a rank number [1-3]: " firstuserrank
    echo "That's all the informatio I'll need for now."
    echo "Setting up the cowfc users database"
    echo "create database cowfc" | mysql -u root -ppasswordhere
    echo "Now importing dumped cowfc database..."
    mysql -u root -ppasswordhere cowfc </var/www/CoWFC/SQL/cowfc.sql
    echo "Now inserting user $firstuser into the database with password $password, hashed as $hash."
    echo "insert into users (\`Username\`, \`Password\`, \`Rank\`) values ('$firstuser','$hash','$firstuserrank');" | mysql -u root -ppasswordhere cowfc
}
function re() {
    echo "For added security, we recommend setting up Google's reCaptcha.

However, not many people would care about this, so we're making it optional.

Feel free to press the ENTER key at the prompt, to skip reCaptcha setup, or 'y' to proceed with recaptcha setup."
    read -rp "Would you like to set up reCaptcha on this server? [y/N]: " recaptchacontinue
    if [ "$recaptchacontinue" == y ]; then
        echo "In order to log into your Admin interface, you will need to set up reCaptcha keys. This script will walk you through it"
        echo "Please make an account over at https://www.google.com/recaptcha/"
        # Next we will ask the user for their secret key and site keys
        read -rp "Please enter the SECRET KEY you got from setting up reCaptcha: " secretkey
        read -rp "Please enter the SITE KEY you got from setting up reCaptcha: " sitekey
        echo "Thank you! I will now add your SECRET KEY and SITE KEY to /var/www/html/_admin/Auth/Login.php"
        # Replace SECRET_KEY_HERE with the secret key from our $secretkey variable
        #sed -i -e "s/SECRET_KEY_HERE/$secretkey/g" /var/www/html/_admin/Auth/Login.php
        sed -i -e "s/SECRET_KEY_HERE/$secretkey/g" /var/www/html/config.ini
        # Replace SITE_KEY_HERE with the site key from our $sitekey variable
        #sed -i -e "s/SITE_KEY_HERE/$sitekey/g" /var/www/html/_admin/Auth/Login.php
        sed -i -e "s/recaptcha_site = SITE_KEY_HERE/recaptcha_site = $sitekey/g" /var/www/html/config.ini
    else
        sed -i -e "s/recaptcha_enabled = 1/recaptcha_enabled = 0/g" /var/www/html/config.ini
    fi
}
function set-server-name() {
    echo "This recent CoWFC update allows you to set your server's name"
    echo "This is useful if you want to whitelabel your server, and not advertise it as CoWFC"
    read -rp "Please enter the server name, or press ENTER to accept the default [CoWFC]: " servernameconfig
    if [ -z "$servernameconfig" ]; then
        echo "Using CoWFC as the server name."
    else
        echo "Setting server name to $servernameconfig"
        sed -i -e "s/name = 'CoWFC'/name = '$servernameconfig'/g" /var/www/html/config.ini
    fi
}
function add-cron() {
    echo "Checking if there is a cron available for $USER"
    if ! crontab -l -u "$USER" | grep "@reboot sh /start-altwfc.sh >/cron-logs/cronlog 2>&1"; then
        echo "No cron job is currently installed"
        echo "Working the magic. Hang tight!"
        cat >/start-altwfc.sh <<EOF
#!/bin/sh
cd /
chmod 777 /var/www/dwc_network_server_emulator -R
cd var/www/dwc_network_server_emulator
python master_server.py
cd /
EOF
        chmod 777 /start-altwfc.sh
        mkdir -p /cron-logs
        if ! command -v crontab; then
            apt install cron -y
        fi
        echo "Creating the cron job now!"
        echo "@reboot sh /start-altwfc.sh >/cron-logs/cronlog 2>&1" >/tmp/alt-cron
        crontab -u "$USER" /tmp/alt-cron
        echo "Done!"
    fi
}
function install_website() {
    # First we will delete evertyhing inside of /var/www/html
    rm -rf /var/www/html/*
    # Let's download the HTML5 template SBAdmin so that the Admin GUI looks nice
    # Download the stuff
    #wget https://github.com/BlackrockDigital/startbootstrap-sb-admin/archive/gh-pages.zip -O sb-admin.zip
    #unzip sb-admin.zip
    #if [ $? != "0" ] ; then
    #	apt  install unzip -y
    #	unzip sb-admin.zip
    #fi
    # Copy required directories and files to /var/www/html
    #cp /var/www/startbootstrap-sb-admin-gh-pages/css/ /var/www/html/ -R && cp /var/www/startbootstrap-sb-admin-gh-pages/js /var/www/html/ -R && cp /var/www/startbootstrap-sb-admin-gh-pages/scss/ /var/www/html/ -R && cp /var/www/startbootstrap-sb-admin-gh-pages/vendor/ /var/www/html/ -R

    # We'll download and install the main template next

    #wget https://html5up.net/landed/download -O html5up-landed.zip
    #unzip html5up-landed.zip -d landed

    # We could put varous cp commands here to copy the needed files
    # Then we will copy the website files from our CoWFC Git
    mkdir /var/www/html
    cp /var/www/CoWFC/Web/* /var/www/html -R
    chmod 777 /var/www/html/bans.log
    # Let's restart Apache now
    service apache2 restart
    echo "Creating gpcm.db file"
    touch /var/www/dwc_network_server_emulator/gpcm.db
    chmod 777 /var/www/dwc_network_server_emulator/ -R
}

# MAIN
# Call update function
if [ "$1" != "-s" ]; then # If there is no -s argument then run the updater
    update                # This will call our update function
fi
#echo "******************************************* WARNING!*******************
#*****************************************************************************
#IT HAS BEEN DISCOVERED THAT BUILDS ON THE LATEST UBUNTU UPDATES WILL FAIL!
#*****************************************************************************
#"
#read -p "Press [ENTER] to continue at your own risk, or ctrl+c to abort."
# First we will check if we are on Ubuntu - this isn't 100% going to work,
# but if we're running Debian, it should be enough for what we need this check
# to do.
if [ -f /etc/lsb-release ]; then
    if grep -q "24.04" /etc/lsb-release; then
        CANRUN="TRUE"
    elif [ -f /var/www/.aws_install ]; then
        CANRUN="TRUE"
    else
        echo "It looks like you are not running on a supported OS."
        echo "Please open an issue and request support for this platform."
        echo "Only Ubuntu 24.04 is supported."
    fi
fi

# Determine if our script can run
if [ "$CANRUN" == "TRUE" ]; then
    # Our script can run since we are on Ubuntu
    # Put commands or functions on these lines to continue with script execution.
    # The first thing we will do is to update our package repos but let's also make sure that the user is running the script in the proper directory /var/www
    if [ "$PWD" == "/var/www" ]; then
        apt update
        # Let's install required packages first.
        install_required_packages
        # Then we will check to see if the Gits for CoWFC and dwc_network_server_emulator exist
        if [ ! -d "/var/www/CoWFC" ]; then
            echo "Git for CoWFC does not exist in /var/www/"
            while ! git clone https://github.com/predadorBR/CoWFC.git && [ "$C1" -le "4" ]; do
                echo "GIT CLONE FAILED! Retrying....."
                ((C1 = C1 + 1))
            done
            if [ "$C1" == "5" ]; then
                echo "Giving up"
                exit 1
            fi
        fi
        if [ ! -d "/var/www/dwc_network_server_emulator" ]; then
            echo "Git for dwc_network_server_emulator does not exist in /var/www"
            while ! git clone https://github.com/predadorBR/dwc_network_server_emulator.git && [ "$C2" -le "4" ]; do
                echo "GIT CLONE FAILED! Retrying......"
                ((C2 = C2 + 1))
            done
            if [ "$C2" == "5" ]; then
                echo "Giving up"
                exit 1
            fi
            echo "Setting proper file permissions"
            chmod 777 /var/www/dwc_network_server_emulator/ -R
        fi
        # Configure DNSMASQ
        if [ ! -f /var/www/dnsmasq-added ]; then
	   dns_config
	fi
        # Let's set up Apache now
        create_apache_vh_nintendo
        create_apache_vh_wiimmfi
        apache_mods     # Enable reverse proxy mod and PHP 8.3
        install_website # Install the web contents for CoWFC
        config_mysql    # We will set up the mysql password as "passwordhere" and create our first user
        re              # Set up reCaptcha
        add-cron        #Makes it so master server can start automatically on boot
        set-server-name # Set your server's name
        #a fix to fix issue: polaris-/dwc_network_server_emulator#413
        cat >>/etc/apache2/apache2.conf <<EOF
HttpProtocolOptions Unsafe LenientMethods Allow0.9
EOF
        echo "Moving the configuration file for more security..."
        mv /var/www/html/config.ini /var/www/config.ini
        echo "Done!"
        # Let's make our hidden file so that our script will know that we've already installed the server
        # This will prevent accidental re-runs
        echo "Finishing..."
	# Remove open resolver
	sed -i '/server=8.8.8.8/d' /etc/dnsmasq.conf
	systemctl reload dnsmasq.service
        touch /etc/.dwc_installed
        echo "Thank you for installing CoWFC."
        echo "If you wish to access the admin GUI, please go to http://$IP/?page=admin&section=Dashboard"
        read -rp "Please hit the ENTER key to reboot now, or press ctrl+c and reboot whenever it is convenient for you: [ENTER] " rebootenterkey
        if [ -z "$rebootenterkey" ]; then
            reboot
        fi
        reboot
        exit 0
    # DO NOT PUT COMMANDS UNDER THIS FI
    fi
else
    echo "Sorry, you do not appear to be running a supported Operating System."
    echo "Please make sure you are running Ubuntu 24.04, and try again!"
    exit 1
fi
