#!/bin/bash -e
#
# from https://gist.github.com/corny/3cf7af0f6cb7a00adeb3
# Improved backup script for Ubiquiti UniFi controller
# original source: http://wiki.ubnt.com/UniFi#Automated_Backup
#

[ "${DEBUG:-false}" = "true" ] && set -x

output="${BACKUP_DIR:-/tmp}"
filename=$(date +%Y%m%d%H%M).unf
keep_days=1
site_id="${UNIFI_SITE_ID:-default}"

# create output directory
mkdir -p "$output"

curl_cmd="curl --cookie /tmp/cookie --cookie-jar /tmp/cookie --insecure --silent --fail"

# authenticate against unifi controller 
if ! $curl_cmd --fail --data "$(jq --null-input --arg username "${UNIFI_USERNAME}" --arg password "${UNIFI_PASSWORD}" '{"username": $username, "password": $password}')" "${UNIFI_URL}/api/login" > /dev/null; then
  echo Login failed
  exit 1
fi

# ask controller to do a backup, response contains the path to the backup file 
path=$($curl_cmd --fail --data 'json={"cmd":"backup","days":"-1"}' "${UNIFI_URL}/api/s/${site_id}/cmd/system" | sed -n 's/.*\(\/dl.*unf\).*/\1/p')

# download the backup to the destinated output file 
$curl_cmd --fail "${UNIFI_URL}$path" -o "$output/$filename"

if [ ! -s "$output/$filename" ]; then
  echo "Backup empty"
  exit 1
fi

# logout 
$curl_cmd --fail "${UNIFI_URL}/logout"

# delete outdated backups
find "$output" -ctime +$keep_days -type f -delete

echo Backup successful

