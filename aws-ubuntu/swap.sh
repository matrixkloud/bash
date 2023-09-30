#!/bin/bash

# Define the swapfile name as a variable (you can change it here if needed)
SWAPFILE="/swapfile"

# Get the total RAM in kilobytes
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')

# Calculate the expected swap size based on total RAM (2 times the RAM size), rounded to the nearest whole number of gigabytes
EXPECTED_SWAP_SIZE_GB=$(( (TOTAL_RAM_KB / (1024*1024) * 2 + 1) / 2 ))

# Check if the swap file already exists
if [ -f "$SWAPFILE" ]; then
    # Get the current swap size in gigabytes
    CURRENT_SWAP_SIZE_GB=$(du -h "$SWAPFILE" | awk '{print $1}')

    if [ "$CURRENT_SWAP_SIZE_GB" == "${EXPECTED_SWAP_SIZE_GB}G" ]; then
        echo "Swap file already exists and is the correct size (${EXPECTED_SWAP_SIZE_GB} GB)."
        exit 1
    else
        # Print a message indicating that the existing swap file size doesn't match
        echo "Existing swap file size ($CURRENT_SWAP_SIZE_GB) does not match the expected size (${EXPECTED_SWAP_SIZE_GB} GB). Deleting the existing swap file."
        sudo swapoff "$SWAPFILE"
        sudo rm "$SWAPFILE"
        echo "Existing swap file deleted."
    fi
fi


# Create a new swap file with the calculated size if it doesn't exist
if [ ! -f "$SWAPFILE" ]; then
    # Calculate the size in megabytes (MB)
    SWAP_SIZE_MB=$(echo "scale=0; $EXPECTED_SWAP_SIZE_GB * 1024" | bc)

    sudo fallocate -l ${SWAP_SIZE_MB}M "$SWAPFILE"

    # Secure the swap file by restricting access
    sudo chmod 600 "$SWAPFILE"

    # Set up the swap area
    sudo mkswap "$SWAPFILE"

    # Enable the swap file
    sudo swapon "$SWAPFILE"

    # Verify the swap is active
    sudo swapon --show

    # Display the amount of swap space created
    free -h

    echo "Swap memory of $EXPECTED_SWAP_SIZE_GB GB has been added."
else
    echo "Swap file already exists. No changes made."
fi

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

echo "Done."
