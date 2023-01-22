printf "SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 0 * * MON root /bin/bash /root/send.sh > /dev/null 2>&1
" > /etc/cron.d/sendweek
