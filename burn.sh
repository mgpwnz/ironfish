sudo tee /root/send.sh > /dev/null <<EOF
echo y | ironfish wallet:burn -a 0.00000001 -f "$IRON" -i $address -o 0.00000001
EOF
