#!/bin/bash

# Define the swapfile name as a variable (you can change it here if needed)
SWAPFILE="/swapfile"

# Get the total RAM in kilobytes
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')

# Calculate the swap size based on total RAM
# For example, you can set it as 2 times the RAM size
SWAP_SIZE_MB=$((TOTAL_RAM_KB / 1024 * 2))

# Check if the swap file already exists
if [ -f "$SWAPFILE" ]; then
    # Get the current swap size in MB
    CURRENT_SWAP_SIZE_MB=$(du -m "$SWAPFILE" | cut -f1)

    if [ "$CURRENT_SWAP_SIZE_MB" -eq "$SWAP_SIZE_MB" ]; then
        echo "Swap file already exists and is the correct size."
        exit 1
    else
        # Delete the existing swap file
        sudo swapoff "$SWAPFILE"
        sudo rm "$SWAPFILE"
        echo "Existing swap file deleted."
    fi
fi

# Create a new swap file with the calculated size
sudo fallocate -l ${SWAP_SIZE_MB}M "$SWAPFILE"

# Secure the swap file by restricting access
sudo chmod 600 "$SWAPFILE"

# Set up the swap area
sudo mkswap "$SWAPFILE"

# Enable the swap file
sudo swapon "$SWAPFILE"

# Define the line to add to /etc/fstab
line_to_add="$SWAPFILE none swap sw 0 0"

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

