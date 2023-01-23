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
	if [ ! $IRONFISH_WALLET ]; then
		read -p "Enter wallet name: " IRONFISH_WALLET
		echo 'export IRONFISH_WALLET='${IRONFISH_WALLET} >> $HOME/.bash_profile
	fi
	echo -e '\n\e[42mYour wallet name:' $IRONFISH_WALLET '\e[0m\n'
	if [ ! $IRONFISH_NODENAME ]; then
		read -p "Enter node name: " IRONFISH_NODENAME
		echo 'export IRONFISH_NODENAME='${IRONFISH_NODENAME} >> $HOME/.bash_profile
	fi
	echo -e '\n\e[42mYour node name:' $IRONFISH_NODENAME '\e[0m\n'
	echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
	. $HOME/.bash_profile
	sleep 1
}

function installSnapshot {
	echo -e '\n\e[42mInstalling snapshot...\e[0m\n' && sleep 1
	systemctl stop ironfishd
	sleep 5
	ironfish chain:download --confirm
	sleep 3
	systemctl restart ironfishd
}
function backupWallet {
	echo -e '\n\e[42mPreparing to backup default wallet...\e[0m\n' && sleep 1
	echo -e '\n\e[42mYou can just press enter if you want backup your default wallet\e[0m\n' && sleep 1
	read -e -p "Enter your wallet name [default]: " IRONFISH_WALLET_BACKUP_NAME
	IRONFISH_WALLET_BACKUP_NAME=${IRONFISH_WALLET_BACKUP_NAME:-default}
	cd $HOME/ironfish/ironfish-cli/
	mkdir -p $HOME/.ironfish/keys
	ironfish wallet:export $IRONFISH_WALLET_BACKUP_NAME $HOME/.ironfish/keys/$IRONFISH_WALLET_BACKUP_NAME.json
	echo -e '\n\e[42mYour key file:\e[0m\n' && sleep 1
	walletBkpPath="$HOME/.ironfish/keys/$IRONFISH_WALLET_BACKUP_NAME.json"
	cat $HOME/.ironfish/keys/$IRONFISH_WALLET_BACKUP_NAME.json
	echo -e "\n\nImport command:"
	echo -e "\e[7mironfish wallet:import $walletBkpPath\e[0m"
	cd $HOME
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

function createConfig {
	mkdir -p $HOME/.ironfish
	echo "{
		\"nodeName\": \"${IRONFISH_NODENAME}\",
		\"blockGraffiti\": \"${IRONFISH_NODENAME}\"
	}" > $HOME/.ironfish/config.json
}

function installSoftware {
	. $HOME/.bash_profile
	. $HOME/.cargo/env
	echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1
	rm -rf ~/.ironfish/databases
	cd $HOME
	npm install -g ironfish
}

function updateSoftware {
	if service_exists ironfishd-pool; then
		sudo systemctl stop ironfishd-pool
	fi
	sudo systemctl stop ironfishd
	. $HOME/.bash_profile
	. $HOME/.cargo/env
	cp -r $HOME/.ironfish/databases/wallet $HOME/ironfish_accounts_$(date +%s)
	echo -e '\n\e[42mUpdate software\e[0m\n' && sleep 1
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
function quest {
wget -O mbs.sh https://raw.githubusercontent.com/cyberomanov/ironfish-mbs/main/mbs.sh && \
chmod u+x mbs.sh
printf "SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
00 22 * * 1,4 root /bin/bash /root/mbs.sh > /dev/null 2>&1
" > /etc/cron.d/mbs
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
}

PS3='Please enter your choice (input your option number and press enter): '
#options=("Install" "Upgrade" "Backup wallet" "Install snapshot" "Delete" "Quest" "Quit")
options=("Install" "Quest" "Upgrade" "Backup wallet" "Delete" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install")
            echo -e '\n\e[42mYou choose install...\e[0m\n' && sleep 1
			setupVars
			installDeps
			installSoftware
			installService
			createConfig
			break
            ;;
        "Upgrade")
            echo -e '\n\e[33mYou choose upgrade...\e[0m\n' && sleep 1
			setupVars
			updateSoftware
			echo -e '\n\e[33mYour node was upgraded!\e[0m\n' && sleep 1
			break
            ;;
		"Backup wallet")
			echo -e '\n\e[33mYou choose backup wallet...\e[0m\n' && sleep 1
			backupWallet
			echo -e '\n\e[33mYour wallet was saved in $HOME/.ironfish/keys folder!\e[0m\n' && sleep 1
			break
            ;;
		 "Install snapshot")
			 echo -e '\n\e[33mYou choose install snapshot...\e[0m\n' && sleep 1
			 installSnapshot
			 echo -e '\n\e[33mSnapshot was installed, node was started.\e[0m\n' && sleep 1
			 break
             ;;
	     	"Quest")
			echo -e '\n\e[33mYou choose quest...\e[0m\n' && sleep 1
			quest
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
