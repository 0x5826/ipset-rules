#!/bin/bash

proxy_sets="./proxy_sets.nft"

lines_number(){
    wc -l $1 | awk -F ' ' '{print $1}'
}

generate_chnroute_v4() {
    local chnroute_v4_tmp="./chnroute_v4_tmp.txt"
    local chnroute_v4_list="./chnroute_v4.txt"

    curl -fsSL 'https://cdn.jsdelivr.net/gh/17mon/china_ip_list@master/china_ip_list.txt' > $chnroute_v4_tmp

    if [ $? -eq 0 ];then
        mv $chnroute_v4_tmp $chnroute_v4_list
        echo -e "[INFO] Updated chnroute_v4 $(lines_number $chnroute_v4_list) items"
    else
        rm -f $chnroute_v4_tmp
        echo -e "[ERROR] Download failed"
        exit 1
    fi

    chnroute_v4_head='define chnroute_v4 = '
    chnroute_v4_body=$(cat $chnroute_v4_list | sed ':label;N;s/\n/, /;b label' | sed 's/$/& }/g' | sed 's/^/{ &/g')
    echo $chnroute_v4_head $chnroute_v4_body >> $proxy_sets
    rm -f $chnroute_v4_list
}

generate_chnroute_v6() {
    local chnroute_v6_tmp="./chnroute_v6_tmp.txt"
    local chnroute_v6_list="./chnroute_v6.txt"

    curl -fsSL 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv6 | grep CN | \
    awk -F\| '{ printf("%s/%d\n", $4, $5) }' \
    > $chnroute_v6_tmp

    if [ $? -eq 0 ];then
        mv $chnroute_v6_tmp $chnroute_v6_list
        echo -e "[INFO] Updated chnroute_v6 $(lines_number $chnroute_v6_list) items"
    else
        rm -f $chnroute_v6_tmp
        echo -e "[ERROR] Download failed"
        exit 1
    fi

    chnroute_v6_head='define chnroute_v6 = '
    chnroute_v6_body=$(cat  $chnroute_v6_list | sed ':label;N;s/\n/, /;b label'| sed 's/$/& }/g' | sed 's/^/{ &/g')
    echo $chnroute_v6_head $chnroute_v6_body >> $proxy_sets
    rm -f $chnroute_v6_list
}

generate_private_v4() {
    local private_v4_head='define private_v4 = '
    local private_v4_body='{ 0.0.0.0/8, 10.0.0.0/8, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 198.18.0.0/16, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4 }'
    echo $private_v4_head $private_v4_body >> $proxy_sets
}

generate_whitelist_v4(){
    local whitelist_v4_head='define whitelist_v4 = '
    local whitelist_v4_body='{ 192.168.0.1/32 }'
    echo $whitelist_v4_head $whitelist_v4_body >> $proxy_sets
}

generate_common_ports(){
    local common_ports_head='define common_ports = '
    local common_ports_body='{ 21, 22, 23, 53, 80, 123, 143, 194, 443, 465, 587, 853, 993, 995, 998, 2052, 2053, 2082, 2083, 2086, 2095, 2096, 5222, 5228, 5229, 5230, 8080, 8443, 8880, 8888, 8889 }'
    echo $common_ports_head $common_ports_body >> $proxy_sets
}

rm -f proxy_sets
generate_chnroute_v4
generate_chnroute_v6
generate_private_v4
generate_whitelist_v4
generate_common_ports