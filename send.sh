sudo tee /root/send.sh > /dev/null <<EOF
echo y | ironfish wallet:send -a 0.00000001 -f "$IRON" -i d7c86706f5817aa718cd1cfad03233bcd64a7789fd9422d3b17af6823a7e6ac6 -t dfc2679369551e64e3950e06a88e68466e813c63b100283520045925adbe59ca -o 0.00000001
EOF
