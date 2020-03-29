# cowfc

This script installs the CoWFC front-end and back-end from https://github.com/EnergyCube/CoWFC

# CONTRIBUTING

Please open pull requests for the dev branch.

# How to use

## Phase 1
`mkdir /var/www ; cd /var/www && wget https://raw.githubusercontent.com/EnergyCube/cowfc_installer/master/cowfc.sh && chmod +x cowfc.sh && ./cowfc.sh`

or

-	`mkdir /var/www`
-	`cd /var/www`
-	`wget https://raw.githubusercontent.com/EnergyCube/cowfc_installer/master/cowfc.sh`
-	`chmod +x cowfc.sh`
-	`./cowfc.sh`

## Phase 2
After system reboot : `cd /var/www && ./cowfc.sh`

or

-	`cd /var/www`
-	`./cowfc.sh`

# NOTES

This script comes in 3 phases. Each phase involves a reboot
-	Add the PHP 7.1 repo
-	Continue CoWFC install
-	Reboot after CoWFC install
