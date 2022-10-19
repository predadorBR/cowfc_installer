#!/bin/bash
sudo su
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
