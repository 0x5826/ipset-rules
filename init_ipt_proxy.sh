#!/bin/bash

interface="ens160"

redirect_port="7892"
tproxy_port="7893"

tproxy_mark="666"
clash_mark="777"

redir_local="PROXY_LOCAL"
tproxy_lan="PROXY_LAN"

init_ipset() {
    rules_path="/etc/clash/ipt_clash_rules"

    ipset restore -f $rules_path/ipset_chnroute_v4
    sleep 1
    ipset restore -f $rules_path/ipset_whitelist_v4
    sleep 1
    ipset restore -f $rules_path/ipset_common_ports
    sleep 1
    ipset restore -f $rules_path/ipset_private_v4
}

init_ipt_lan_snat() {
  iptables -t nat -A POSTROUTING -o $interface -j MASQUERADE
}

init_ipt_local_proxy() {
    iptables -t nat -N $redir_local
    iptables -t nat -A $redir_local -m mark --mark $clash_mark -j RETURN
    iptables -t nat -A $redir_local -m set --match-set private_v4 dst -j RETURN
    iptables -t nat -A $redir_local -m set --match-set chnroute_v4 dst -j RETURN
    iptables -t nat -A $redir_local -m set ! --match-set common_ports dst -j RETURN
    iptables -t nat -A $redir_local -p tcp -j REDIRECT --to-ports $redirect_port
    iptables -t nat -A OUTPUT -p tcp -j $redir_local
}

init_ipt_lan_proxy() {
    iptables -t mangle -N $tproxy_lan
    iptables -t mangle -A $tproxy_lan -m mark --mark $clash_mark -j RETURN
    iptables -t mangle -A $tproxy_lan -m set --match-set private_v4 dst -j RETURN
#    iptables -t mangle -A $tproxy_lan -m set --match-set whitelist_v4 src -j RETURN
#    iptables -t mangle -A $tproxy_lan -m set ! --match-set common_ports dst -j RETURN
    iptables -t mangle -A $tproxy_lan -m set --match-set chnroute_v4 dst -j RETURN
    iptables -t mangle -A $tproxy_lan -p tcp -j TPROXY --on-port $tproxy_port --tproxy-mark $tproxy_mark
    iptables -t mangle -A $tproxy_lan -p udp -m multiport --destination-ports 123,443 -j RETURN
    iptables -t mangle -A $tproxy_lan -p udp -j TPROXY --on-port $tproxy_port --tproxy-mark $tproxy_mark
    
    iptables -t mangle -A PREROUTING -j $tproxy_lan

    ip rule add fwmark $tproxy_mark lookup $tproxy_mark
    ip route add default dev lo table $tproxy_mark
}

clean_remain() {
    iptables -t nat -D POSTROUTING -o $interface -j MASQUERADE 2>/dev/null

    iptables -t nat -D OUTPUT -p tcp -j $redir_local 2>/dev/null
    iptables -t mangle -D PREROUTING -j $tproxy_lan 2>/dev/null

    iptables -t nat -F $redir_local 2>/dev/null
    iptables -t nat -X $redir_local 2>/dev/null
    iptables -t mangle -F $tproxy_lan 2>/dev/null
    iptables -t mangle -X $tproxy_lan 2>/dev/null

    ip rule delete fwmark $tproxy_mark lookup $tproxy_mark 2>/dev/null
    ip route delete default dev lo table $tproxy_mark 2>/dev/null

    ipset destroy chnroute_v4 2>/dev/null
    ipset destroy whitelist_v4 2>/dev/null
    ipset destroy common_ports 2>/dev/null
    ipset destroy private_v4 2>/dev/null
}

case "$1" in
    "start")
        clean_remain
        init_ipt_lan_snat
        init_ipt_local_proxy
        init_ipt_lan_proxy
        ;;
    "stop")
        clean_remain
        ;;
    *)
        echo "[ERROR] Unknow option! allow <start> <stop>."
        exit 1
        ;;
esac