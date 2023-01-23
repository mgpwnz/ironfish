#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}

service_exists() {
    local n=$1
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | sed 's/^\s*//g' | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}

if exists curl; then
	echo ''
else
  sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
function setupVars {
if [ ! $MAIL ]; then
		read -p "Enter mail address: " MAIL
		echo 'export MAIL='${MAIL} >> $HOME/.bash_profile
	fi
echo -e '\n\e[42mYour mail address:' $MAIL '\e[0m\n'
if [ ! $IRONFISH_LINK ]; then
		read -p "Enter link to profile or Graffiti: " IRONFISH_LINK
		echo 'export IRONFISH_LINK='${IRONFISH_LINK} >> $HOME/.bash_profile
	fi
echo -e '\n\e[42mYour link(graffiti):' $IRONFISH_LINK '\e[0m\n'
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
	. $HOME/.bash_profile
	sleep 1
}



function installDeps {
	echo -e '\n\e[42mPreparing to install\e[0m\n' && sleep 1
	cd $HOME
	sudo apt update
	sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
	. $HOME/.cargo/env
	curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
	sudo apt update
	sudo apt install curl make clang pkg-config libssl-dev build-essential git jq nodejs -y < "/dev/null"
	sudo apt install npm 
}

function installSoftware {
	. $HOME/.bash_profile
	. $HOME/.cargo/env
	echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1
	rm -rf ~/.ironfish/databases
	cd $HOME
	npm install -g ironfish
}
function connect {
	echo $IRONFISH_LINK | ironfish testnet
	}
function quest {
wget -O mbs.sh https://raw.githubusercontent.com/cyberomanov/ironfish-mbs/main/mbs.sh && \
chmod u+x mbs.sh
printf "SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
00 14 * * MON root /bin/bash /root/mbs.sh > /dev/null 2>&1
" > /etc/cron.d/mbs
sleep 2
wget -O faucet.sh https://raw.githubusercontent.com/mgpwnz/ironfish/main/faucet.sh && \
chmod u+x faucet.sh
printf "SHELL=/bin/bash                                                
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin      
30 13 * * MON root /bin/bash /root/faucet.sh > /dev/null 2>&1            
" > /etc/cron.d/afish                                                  
}

function updateSoftware {
	sudo systemctl stop ironfishd
	cd $HOME
	npm update -g ironfish
	sudo systemctl restart ironfishd
	sleep 2
	if [[ `service ironfishd status | grep active` =~ "running" ]]; then
          echo -e "Your IronFish node \e[32mupgraded and works\e[39m!"
          echo -e "You can check node status by the command \e[7mservice ironfishd status\e[0m"
          echo -e "Press \e[7mQ\e[0m for exit from status menu"
        else
          echo -e "Your IronFish node \e[31mwas not upgraded correctly\e[39m, please reinstall."
        fi
	 . $HOME/.bash_profile
}

function installService {
echo -e '\n\e[42mRunning\e[0m\n' && sleep 1
echo -e '\n\e[42mCreating a service\e[0m\n' && sleep 1
echo "[Unit]
Description=IronFish Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which ironfish) start
Restart=always
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
" > $HOME/ironfishd.service
sudo mv $HOME/ironfishd.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
echo -e '\n\e[42mRunning a service\e[0m\n' && sleep 1
sudo systemctl enable ironfishd
sudo systemctl restart ironfishd
echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service ironfishd status | grep active` =~ "running" ]]; then
  echo -e "Your IronFish node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice ironfishd status\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
 echo -e "Your IronFish node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
. $HOME/.bash_profile
}

function deleteIronfish {
	sudo systemctl disable ironfishd
	sudo systemctl stop ironfishd
	sudo rm -rf $HOME/ironfish $HOME/.ironfish $(which ironfish)
	sudo rm $HOME/mbs.sh /etc/cron.d/mbs
  	sudo rm /etc/cron.d/afish $HOME/faucet.sh
}

PS3='Please enter your choice (input your option number and press enter): '
options=("Install" "Upgrade" "Delete" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install")
 		echo -e '\n\e[42mYou choose install...\e[0m\n' && sleep 1
			installDeps
			installSoftware
			connect
			installService
			quest
			break
            ;;
	"Upgrade")
            echo -e '\n\e[33mYou choose upgrade...\e[0m\n' && sleep 1
			updateSoftware
			echo -e '\n\e[33mYour node was upgraded!\e[0m\n' && sleep 1
			break
            ;;
	"Delete")
            echo -e '\n\e[31mYou choose delete...\e[0m\n' && sleep 1
			deleteIronfish
			echo -e '\n\e[42mIronfish was deleted!\e[0m\n' && sleep 1
			break
            ;;
        "Quit")
            break
            ;;
        *) echo -e "\e[91minvalid option $REPLY\e[0m";;
    esac
done
