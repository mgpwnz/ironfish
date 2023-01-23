printf "SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
00 11 * * * root /bin/bash /root/faucet.sh > /dev/null 2>&1
" > /etc/cron.d/afish
