# cf-uptimerobot-ip-whitelister

A Bash script to automatically whitelist UptimeRobot's monitoring IPs in your Cloudflare account.

## Prerequisites

Ensure the following tools are installed on your system:
- `curl`
- `jq`

## Configuration

Before running the script, update the following variables in `cf-uptimerobot-ip-whitelister.sh` with your Cloudflare account details:

- `CF_API_TOKEN`: The Cloudflare API Token
- `CF_ACCOUNT_ID`: The Cloudflare Account ID you wish to modify

## Usage

1. Make the script executable:
   ```bash
   chmod +x cf-uptimerobot-ip-whitelister.sh

2. To see the logs
   ```bash
   cat debug.log

