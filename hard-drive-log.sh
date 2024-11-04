#!/bin/bash

# Define log directory and file name format
log_dir="/var/log/apps/wd-hard-drive"
date_format=$(date +%d-%m-%Y)
log_file="$log_dir/$date_format.json"

# Ensure the log directory exists
mkdir -p "$log_dir"

# Run smartctl command to get the required S.M.A.R.T. attributes
output=$(sudo smartctl -A -d sat /dev/sda)

# Extract values for each attribute
temperature=$(echo "$output" | grep -i "temperature" | awk '{print $10}')
power_on_hours=$(echo "$output" | grep -i "power_on_hours" | awk '{print $10}')
start_stop_count=$(echo "$output" | grep -i "start_stop_count" | awk '{print $10}')
spin_up_time=$(echo "$output" | grep -i "spin_up_time" | awk '{print $10}')

# Get the current timestamp in the desired format
current_time=$(date +"%Y-%m-%dT%H:%M:%S")

# Create the JSON output for the log entry
json_entry=$(cat <<EOF
{
    "timestamp": "$current_time",
    "device": "/dev/sda",
    "temperature_celsius": "$temperature",
    "power_on_hours": "$power_on_hours",
    "start_stop_count": "$start_stop_count",
    "spin_up_time": "$spin_up_time"
}
EOF
)

# Check if the log file exists
if [[ ! -f $log_file ]]; then
    # If not, create it and add the new entry in array format
    echo "[" > "$log_file"
    echo "$json_entry" >> "$log_file"
    echo "]" >> "$log_file"
else
    # If the file already exists, append the new entry
    # Temporarily create a new file for editing
    tmp_file=$(mktemp)

    # Read the existing log, remove the closing bracket, add new entry, and close the array
    head -n -1 "$log_file" > "$tmp_file"
    echo "," >> "$tmp_file"
    echo "$json_entry" >> "$tmp_file"
    echo "]" >> "$tmp_file"

    # Replace the original log file with the updated one
    mv "$tmp_file" "$log_file"
fi

# Set permissions to ensure the root user has access
chown root:root "$log_file"
chmod 644 "$log_file"
