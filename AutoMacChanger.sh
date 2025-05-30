#!/bin/bash

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m'
WHITE=$'\033[1;37m'
BLUE=$'\033[1;34m'
# Function to check if interface supports MAC spoofing
is_supported_interface() {
    local iface=$1

    if [[ "$iface" == "lo" ]]; then
        return 1
    fi


    sudo ip link set "$iface" down 2>/dev/null
    sudo macchanger -s "$iface" &>/dev/null
    local result=$?
    sudo ip link set "$iface" up 2>/dev/null

    # Return 0 if spoofing is supported
    return $result
}

# Get list of all interfaces

if [[ $EUID -ne 0 ]]; then
  echo -e "${RED} This script should be run as SUDO..	 ${NC}"
  exit 1
fi
echo -e "\n${RED}$(figlet -f slant MAC - Spoof )\n${NC}"

max_width=$(echo "$FIGLET_TEXT" | awk '{ if ( length > max ) max = length } END { print max }')
echo -e "\n"
echo  -e "${YELLOW}                                        Created by: MohammedAbdulAhadSaud"
echo -e "                                        GitHub: https://github.com/MohammedAbdulAhadSaud/AutoMacChanger${NC}"

ALL_INTERFACES=$(ls /sys/class/net)

# Filter supported ones
SUPPORTED_INTERFACES=()
echo -e  "${BLUE} \n=> Checking supported interfaces...${NC}"
for iface in $ALL_INTERFACES; do
    if is_supported_interface "$iface"; then
        SUPPORTED_INTERFACES+=("$iface")
    fi
done

# Show supported interfaces
if [[ ${#SUPPORTED_INTERFACES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}=>  No interfaces found that support MAC spoofing.${NC}"
    exit 1
fi

echo -e "=> Available interfaces:  \n"
for iface in "${SUPPORTED_INTERFACES[@]}"; do
    echo " > $iface"
done
printf '\n-----------------------------------------------------\n'

# Prompt user to select one
printf  "\n"
read -e -p "${WHITE} > Enter the interface to spoof : " INTERFACE
echo -e  "${NC}"

# Validate chosen interface
if [[ ! " ${SUPPORTED_INTERFACES[@]} " =~ " $INTERFACE " ]]; then
    echo -e "${RED}=> Error: '$INTERFACE' is not in the list of supported interfaces.${NC}"
    exit 1
fi

# Ask for duration

read -e -p "${WHITE} > Enter the duration (in seconds) : " time 
echo -e  "${NC}"
echo -e	 "-----------------------------------------------------"

# Validate time is a positive integer
if [[ ! "$time" =~ ^[0-9]+$ ]]; then
    echo -e  "${RED}=>  Error : Please enter a valid positive integer for duration.${NC}"
    exit 1
fi

# Begin spoofing loop
echo -e "${BLUE}=> Starting MAC spoofing on $INTERFACE every $time seconds...${NC}\n"
while true; do
    sudo ip link set "$INTERFACE" down
    sudo macchanger -r "$INTERFACE"
    sudo ip link set "$INTERFACE" up

    echo -e "=>${GREEN}Sucessfully change MAC address changed for $INTERFACE ${NC}\n"
    sleep "$time"
done

