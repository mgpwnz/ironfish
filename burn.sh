sudo tee /root/burn.sh > /dev/null <<EOF
echo y | ironfish wallet:burn -a 0.00000001 -f "$IRON" -i $AssetId -o 0.00000001
EOF
