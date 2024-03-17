#!/bin/bash
# A simple script to manage the bind9 DNS server

ZONE_PATH="config"
DEFAULT_ZONE_FILE="fileserver.io.zone"
COMPOSE_FILE="compose.yml"

#ZONE_FILE=${2:-$DEFAULT_ZONE_FILE}

# Add entry to the zone file and restart the bind9 service
function add_entry { 
    echo "$1 IN A $2" >> $ZONE_PATH/$ZONE_FILE
    echo "Added $1 -> $2"
    docker compose -f $COMPOSE_FILE restart bind9
}

# Remove entry from the zone file and restart the bind9 service
function remove_entry {
    sed -i "/$1/d" $ZONE_PATH/$ZONE_FILE
    echo "Removed $1"
    docker compose -f $COMPOSE_FILE restart bind9
}

# List all entries in the zone file
function list_entries {
    local HOSTNAME=$1
    #local ZONE_FILE=$2
    echo $ZONE_PATH/$ZONE_FILE # debug
    if [ -z "$HOSTNAME" ]; then
        awk '/NS/ {flag=1} flag' $ZONE_PATH/$ZONE_FILE
    else
        awk -v hostname="$HOSTNAME" '/NS/ {flag=1} flag && $0 ~ hostname' $ZONE_PATH/$ZONE_FILE
    fi
}

# Check the status of the bind9 service
function status {
    if [ "$(docker-compose -f $COMPOSE_FILE ps -q bind9)" ]; then
        echo "bind9 service is running"
    else
        echo "bind9 service is not running, starting it now..."
        docker-compose -f $COMPOSE_FILE up -d bind9
    fi
}

if [ "$1" == "add" ]; then
    ZONE_FILE=${4:-$DEFAULT_ZONE_FILE}
    add_entry $2 $3
elif [ "$1" == "remove" ]; then
    ZONE_FILE=${3:-$DEFAULT_ZONE_FILE}
    remove_entry $2
elif [ "$1" == "list" ]; then
    ZONE_FILE=${3:-$DEFAULT_ZONE_FILE}
    list_entries $2
elif [ "$1" == "status" ]; then
    status
else
    echo "Usage: $0 {add|remove|list|status} [hostname] [ip] [zone_file]"
    echo "  add: Add a new DNS entry. Requires a hostname and an IP. Optionally, provide a zone file."
    echo "  remove: Remove a DNS entry. Requires a hostname. Optionally, provide a zone file."
    echo "  list: List all DNS entries. Optionally, provide a hostname to list a specific entry and a zone file."
    echo "  status: Check the status of the bind9 service. Starts the service if it's not running."
fi