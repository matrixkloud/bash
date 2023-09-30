#!/bin/bash

# Get the total RAM in kilobytes
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')

# Calculate the swap size based on total RAM
# For example, you can set it as 2 times the RAM size
SWAP_SIZE_MB=$((TOTAL_RAM_KB / 1024 * 2))

# Check if the swap file already exists
if [ -f /swapfile ]; then
    echo "Swap file already exists."
    exit 1
fi

# Create a swap file with the calculated size
sudo fallocate -l ${SWAP_SIZE_MB}M /swapfile

# Secure the swap file by restricting access
sudo chmod 600 /swapfile

# Set up the swap area
sudo mkswap /swapfile

# Enable the swap file
sudo swapon /swapfile

# Define the swapfile path
swapfile="/swapfile"

# Define the line to add to /etc/fstab
line_to_add="/swapfile none swap sw 0 0"

# Check if the line already exists in /etc/fstab
if grep -qFx "$line_to_add" /etc/fstab; then
    echo "The line already exists in /etc/fstab. No changes made."
else
    # Add the line to /etc/fstab
    echo "$line_to_add" | sudo tee -a /etc/fstab
    echo "The line has been added to /etc/fstab."
fi

# Verify the swap is active
sudo swapon --show

# Display the amount of swap space created
free -h

echo "Swap memory of ${SWAP_SIZE_MB}MB has been added."
