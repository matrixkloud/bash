#!/bin/bash
# Define the swapfile name as a variable (you can change it here if needed)
SWAPFILE="/swapfile"

# Get the total RAM in kilobytes
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')

# Calculate the expected swap size based on total RAM (following the standard swap calculation)
EXPECTED_SWAP_SIZE_MB=$((TOTAL_RAM_KB * 2 / 1024))

# Function to retry swap off until successful
retry_swapoff() {
    while :
    do
        sudo swapoff "$SWAPFILE"
        if [ $? -eq 0 ]; then
            echo "Swapoff succeeded."
            break  # Exit the loop if swap off was successful
        else
            echo "Swapoff failed. Retrying..."
            sleep 1  # Optional: add a delay between retries
        fi
    done
}

# Check if the swap file already exists
if [ -f "$SWAPFILE" ]; then
    # Get the current swap size in megabytes
    CURRENT_SWAP_SIZE_MB=$(du -m "$SWAPFILE" | awk '{print $1}')

    # Calculate the acceptable range for the current swap size
    LOWER_BOUND=$((EXPECTED_SWAP_SIZE_MB - 100))
    UPPER_BOUND=$((EXPECTED_SWAP_SIZE_MB + 100))

    if [ "$CURRENT_SWAP_SIZE_MB" -ge "$LOWER_BOUND" ] && [ "$CURRENT_SWAP_SIZE_MB" -le "$UPPER_BOUND" ]; then
        echo "Swap file already exists and is within an acceptable size range ($LOWER_BOUND MB to $UPPER_BOUND MB)."
        exit 1
    else
        # Print a message indicating that the existing swap file size doesn't match
        echo "Existing swap file size ($CURRENT_SWAP_SIZE_MB MB) does not match the expected size ($EXPECTED_SWAP_SIZE_MB MB). Deleting the existing swap file."
        retry_swapoff
        sudo rm "$SWAPFILE"
        echo "Existing swap file deleted."
    fi
fi

# Create a new swap file with the calculated size if it doesn't exist
if [ ! -f "$SWAPFILE" ]; then
    # Create the swap file using dd
    sudo dd if=/dev/zero of="$SWAPFILE" bs=1M count="$EXPECTED_SWAP_SIZE_MB"

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

    echo "Swap memory of $EXPECTED_SWAP_SIZE_MB MB has been added."
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

