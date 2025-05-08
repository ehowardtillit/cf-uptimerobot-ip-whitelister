#!/bin/bash

# Enable debugging
set -x

# Configuration - replace these with your actual values
CF_API_TOKEN="TOKEN" # Replace with your Cloudflare API Token
CF_ACCOUNT_ID="ACCOUNT_ID" # Replace with your Cloudflare Account ID

# Debugging log file
DEBUG_LOG="debug.log"
exec > >(tee -a "$DEBUG_LOG") 2>&1

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Ensure required tools are installed
for cmd in curl jq; do
    echo "Checking if $cmd is installed..."
    command -v $cmd >/dev/null 2>&1 || { echo -e "${RED}Error: $cmd is required but not installed.${NC}" >&2; exit 1; }
done

# Check if configuration is set
if [[ -z "$CF_API_TOKEN" || -z "$CF_ACCOUNT_ID" ]]; then
    echo -e "${RED}Error: Please update the script with your Cloudflare API credentials and Account ID.${NC}"
    exit 1
fi

# URL for UptimeRobot IPs
UPTIMEROBOT_IPS_URL="https://uptimerobot.com/inc/files/ips/IPv4andIPv6.txt"

# Fetch UptimeRobot IPs
echo -e "${YELLOW}Fetching UptimeRobot IPs...${NC}"
UPTIMEROBOT_IPS=$(curl -s "$UPTIMEROBOT_IPS_URL" | grep -v "^$")
echo "Fetched IPs: $UPTIMEROBOT_IPS"

if [[ -z "$UPTIMEROBOT_IPS" ]]; then
    echo -e "${RED}Error: Failed to fetch UptimeRobot IPs or the list is empty.${NC}"
    exit 1
fi

IP_COUNT=$(echo "$UPTIMEROBOT_IPS" | wc -l)
echo -e "${GREEN}Successfully fetched $IP_COUNT UptimeRobot IPs.${NC}"

# Whitelist an IP in Cloudflare
whitelist_ip() {
    local ip=$1
    local ip_type=$([[ "$ip" =~ ":" ]] && echo "ip6" || echo "ip")
    echo -e "${YELLOW}Processing IP: $ip (${ip_type})${NC}"

    # Whitelist the IP
    echo -e "${YELLOW}Whitelisting IP $ip...${NC}"
    local response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/firewall/access_rules/rules" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{
            \"mode\": \"whitelist\",
            \"configuration\": { \"target\": \"$ip_type\", \"value\": \"$ip\" },
            \"notes\": \"UptimeRobot Monitoring IP\"
        }")
    #echo "Response from Cloudflare (whitelist_ip): $response"
    local success=$(echo "$response" | jq -r '.success')
    if [[ "$success" == "true" ]]; then
        echo -e "${GREEN}Successfully whitelisted $ip${NC}"
        return 0
    else
        local error=$(echo "$response" | jq -r '.errors[0].message')
        if [[ "$error" =~ "already exists" ]]; then
            echo -e "${YELLOW}IP $ip is already whitelisted.${NC}"
            return 0
        else
            echo -e "${RED}Failed to whitelist $ip: $error${NC}"
            return 1
        fi
    fi
}

# Main function
echo -e "${YELLOW}Starting to whitelist IPs...${NC}"
temp_count_file=$(mktemp)
echo "0" > "$temp_count_file"

# Debugging UPTIMEROBOT_IPS
#echo "UPTIMEROBOT_IPS content:"
#echo "$UPTIMEROBOT_IPS"

# Ensure the variable is not empty
if [[ -z "$UPTIMEROBOT_IPS" ]]; then
    echo -e "${RED}Error: UPTIMEROBOT_IPS is empty. Check the URL or network connection.${NC}"
    exit 1
fi

while read -r ip; do
    echo "Processing IP: $ip"
    if whitelist_ip "$ip"; then
        current_count=$(<"$temp_count_file")
        echo $((current_count + 1)) > "$temp_count_file"
    fi
done <<< "$UPTIMEROBOT_IPS"

success_count=$(<"$temp_count_file")
rm "$temp_count_file"

echo -e "${GREEN}Completed! Successfully processed $success_count out of $IP_COUNT UptimeRobot IPs.${NC}"
