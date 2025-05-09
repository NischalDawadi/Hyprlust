#!/bin/bash

# Path to your icons
ICON_PATH="$HOME/.config/hypr/icons"

# Function to send notifications
send_notification() {
    local title="$1"
    local message="$2"
    notify-send "$title" "$message"
}

# Function to check battery status
check_battery_status() {
    # Get battery capacity and status
    local capacity=$(cat /sys/class/power_supply/BAT0/capacity)
    local status=$(cat /sys/class/power_supply/BAT0/status)

    # Check for notifications
    if [ "$capacity" -le 20 ] && [ "$previous_status" != "low" ]; then
         notify-send -u critical -i "$ICON_PATH/battery-low.png" "Battery at 20%" "Please plug in your charger."
        previous_status="low"
    elif [ "$capacity" -eq 100 ] && [ "$previous_status" != "full" ]; then
         notify-send -u normal -i "$ICON_PATH/battery-full.png" "Battery at 100%" "Your battery is fully charged. You can unplug your device."
        previous_status="full"
    fi

    # Check for plugging/unplugging events
    if [ "$status" == "Charging" ] && [ "$previous_power_status" != "plugged" ]; then
        notify-send -u normal -i "$ICON_PATH/battery-charging.png" "Charging" "Charger is plugged in."
        previous_power_status="plugged"
    elif [ "$status" == "Discharging" ] && [ "$previous_power_status" != "unplugged" ]; then
        notify-send -u normal -i "$ICON_PATH/battery-unplugged.png" "Discharging" "Charger is unplugged."
        previous_power_status="unplugged"
    fi
}

# Initialize previous states
previous_status=""
previous_power_status=""

# Run the check in an infinite loop
while true; do
    check_battery_status
    sleep 60  # Check every minute
done
