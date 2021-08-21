#!/bin/bash

# socat -v TCP-LISTEN:12345,fork SYSTEM:"./HostTranslate.sh tracker.example.com 100000 `date -u +%s`"

tracker_host="$1"
rate="$2"

function get_incremental_upload
{
    hash="$1"
    uploaded=$(cat "$hash.json" | jq .uploaded_at_last_update)
    last_update_time=$(cat "$hash.json" | jq .last_update_time)
    seconds="$[`date -u +%s`-last_update_time]"
    incremental_upload=$(echo "scale=40;$2*(0.8+0.4*(`date +%N | head -c5`/100000))*$seconds" | \
        bc | cut -d '.' -f1)
    echo "$[uploaded+incremental_upload]"
}

cat - | while read line
do
    hash=$(echo "$line" | grep -o 'hash=[^&"]*' | cut -d '=' -f2 | tr -d '%')
    reported_upload=$(echo "$line" | grep -o "uploaded=[0-9]*" | cut -d '=' -f2)

    if [ "$hash" != "" ]
    then
        if [ ! -f "$hash.json" ]
        then
            echo "{\"uploaded_at_last_update\": $reported_upload, \"last_update_time\": `date -u +%s`, \"start_time\": `date -u +%s`}" > "$hash.json"
        fi

        new_up_bytes=$(get_incremental_upload "$hash" "$rate")
        echo "NEW_UP_BYTES $hash $new_up_bytes" >&2

        cat "$hash.json" | \
            jq ".uploaded_at_last_update = $new_up_bytes | .last_update_time = `date -u +%s`" | \
            sponge "$hash.json"

        echo "$line" | \
        sed -u "s/^[Hh]ost:.*$/Host: ${tracker_host}\r/" | \
        sed -u "s/left=[0-9]*/left=0/" | \
        sed -u "s/downloaded=[0-9]*/downloaded=0/" | \
        sed -u "s/uploaded=[0-9]*/uploaded=$new_up_bytes/" | \
        tee -a "outbound.$hash"
    else
        echo "$line"
    fi
done | \
    openssl s_client -quiet \
        -connect "${tracker_host}:443" \
        -servername "${tracker_host}" 2>/dev/null
