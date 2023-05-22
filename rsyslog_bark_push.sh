#!/bin/bash

Serverdate=$(date +'%Y-%m-%d %H:%M')

vote() {
        curl -sL "https://bark.duckduckfly.xyz/CnSyKZvQfzgwhuQwrfdqWS/Decred中票通知/"$Serverdate"?level=timeSensitive?sound=alarm"
        exit 0
}

purchase() {
        curl -sL "https://bark.duckduckfly.xyz/CnSyKZvQfzgwhuQwrfdqWS/Decred购票通知/"$Serverdate"?level=timeSensitive?sound=alarm"
        exit 0
}

case "$1" in
    "vote")
        vote
        ;;
    "purchase")
        purchase
        ;;
    *)
        echo "[ERROR] Unknow option! allow <vote> <purchase>."
        exit 1
        ;;
esac