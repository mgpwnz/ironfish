#!/bin/sh
echo $MAIL | ironfish faucet | tee -a /root/logfile.log
