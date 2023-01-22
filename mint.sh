sudo tee /root/mint.sh > /dev/null <<EOF
echo y | ironfish wallet:mint -a 0.1 -f "$IRON" -m $IRONFISH_WALLET -n $IRONFISH_WALLET -o 0.00000001 | tee -a /root/logfile.log
EOF
