#!/bin/sh
#v 0.1
if [ ! $MAIL ]; then
		read -p "Enter mail address: " MAIL
		echo 'export MAIL='${MAIL} >> $HOME/.bash_profile
	fi
  echo -e '\n\e[42mYour mail address:' $MAIL '\e[0m\n'
  echo $MAIL | ironfish faucet | tee -a /root/logfile.log



#########################################################################
#printf "SHELL=/bin/bash                                                #
#PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin      #
#00 11 * * * root /bin/bash /root/faucet.sh > /dev/null 2>&1            #
#" > /etc/cron.d/afish                                                  #
#########################################################################
