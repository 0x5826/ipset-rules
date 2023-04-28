#!/bin/sh

mkdir ipset_rules && cd ipset_rules

lines_number(){
    wc -l $1 | awk -F ' ' '{print $1}'
}
generate_chnroute_v4_v6(){
    local chnroute_v4_tmp="./chnroute_v4_tmp.txt"
    local chnroute_v6_tmp="./chnroute_v6_tmp.txt"
    local chnroute_v4_list="./chnroute_v4.txt"
    local chnroute_v6_list="./chnroute_v6.txt"
    local chnroute_v4_ipset="./ipset_chnroute_v4"
    local chnroute_v6_ipset="./ipset_chnroute_v6"

    #curl -fsSL 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv4 | grep CN | \
    #awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' \
    #> $chnroute_v4_tmp

    curl -fsSL 'https://cdn.jsdelivr.net/gh/17mon/china_ip_list@master/china_ip_list.txt' > $chnroute_v4_tmp
    if [ $? -eq 0 ];then
        mv $chnroute_v4_tmp $chnroute_v4_list
        echo -e "[INFO] Updated chnroute_v4 $(lines_number $chnroute_v4_list) items"
    else
        rm -f $chnroute_v4_tmp
        echo -e "[ERROR] Download failed"
        exit 1
    fi

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

    echo "create chnroute_v4 hash:net family inet hashsize 4096 maxelem 65536" > $chnroute_v4_ipset
    for ips in `cat $chnroute_v4_list`
    do
        echo "add chnroute_v4 $ips" >> $chnroute_v4_ipset
    done
    echo -e "[INFO] file $chnroute_v4_ipset: $(lines_number $chnroute_v4_ipset)"

    echo "create chnroute_v6 hash:net family inet6 hashsize 4096 maxelem 65536" > $chnroute_v6_ipset
    for ips in `cat $chnroute_v6_list`
    do
        echo "add chnroute_v6 $ips" >> $chnroute_v6_ipset
    done
    echo -e "[INFO] file $chnroute_v6_ipset: $(lines_number $chnroute_v6_ipset)"

    rm -f $chnroute_v4_tmp
    rm -f $chnroute_v6_tmp
    rm -f $chnroute_v4_list
    rm -f $chnroute_v6_list
}

generate_common_ports(){
    local ipset_common_ports="./ipset_common_ports"

    common_ports="21 22 23 53 80 123 143 194 443 \
    465 587 853 993 995 998 \
    2052 2053 2082 2083 2086 2095 2096 \
    5222 5228 5229 5230 8080 8443 8880 8888 8889"
    
    echo "create common_ports bitmap:port range 0-65535" > $ipset_common_ports

    for common_port in $common_ports
    do 
        echo "add common_ports $common_port" >> $ipset_common_ports
    done

    echo -e "[INFO] file $ipset_common_ports: $(lines_number $ipset_common_ports)"
}

generate_whitelist_v4(){
    local ipset_whitelist_v4="./ipset_whitelist_v4"
    
    echo "create whitelist_v4 hash:net family inet hashsize 4096 maxelem 65536" > $ipset_whitelist_v4
    echo "add whitelist_v4 192.168.0.1" >> $ipset_whitelist_v4

    echo -e "[INFO] file $ipset_whitelist_v4: $(lines_number $ipset_whitelist_v4)"
}

generate_private_v4(){
    local ipset_private_v4="./ipset_private_v4"
    
    echo "create private_v4 hash:net family inet hashsize 4096 maxelem 65536" > $ipset_private_v4
    echo "add private_v4 0.0.0.0/8" >> $ipset_private_v4
    echo "add private_v4 10.0.0.0/8" >> $ipset_private_v4
    echo "add private_v4 127.0.0.0/8" >> $ipset_private_v4
    echo "add private_v4 169.254.0.0/16" >> $ipset_private_v4
    echo "add private_v4 172.16.0.0/12" >> $ipset_private_v4
    echo "add private_v4 198.18.0.0/16" >> $ipset_private_v4
    echo "add private_v4 192.168.0.0/16" >> $ipset_private_v4
    echo "add private_v4 224.0.0.0/4" >> $ipset_private_v4
    echo "add private_v4 240.0.0.0/4" >> $ipset_private_v4

    echo -e "[INFO] file $ipset_private_v4: $(lines_number $ipset_private_v4)"
}
pwd
generate_chnroute_v4_v6
generate_whitelist_v4
generate_private_v4
generate_common_ports
