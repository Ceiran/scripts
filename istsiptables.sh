#!/bin/bash
#box names
boxes="acidburn pwnsauce viral anarchaos kayla avunit tflow"
#Ports
p_ssh="22"
p_http="80"
p_https="443"
p_vnc="7900 7901 7902"
p_imap="143"
p_smtp="25"
p_xmpp="5222 5269 5223"
p_es="9200 9300 9600 5601"

#Check to see if positional parameter 1 exists
match="no"
if [ -z "$1" ]; then
  echo "Positional parameter 1 is empty. Please enter a box name."
else
  for name in $boxes
  do
    if [ $1 = $name ]; then
      match="yes"
      if [ $1 = "pwnsauce"] || [ $1 = "kayla"] || [ $1 = "tflow" ]; then
        firewall-cmd --set-default-zone=public
        
        in_ports="$p_ssh $p_http $p_https"
        for port in $in_ports
        do
          firewall-cmd --permanent --add-port=$port/TCP
        done
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https

        firewall-cmd --permanent --remove-service=mysql

        firewall-cmd --reload


        echo "firewalld rules set"
        exit 0
      fi
    fi
  done
  if [ $match = "no" ]; then
    echo "Not a valid box name."
  else
    #IPv6
    ip6tables -F
    ip6tables -X
    ip6tables -t mangle -F
    ip6tables -t mangle -X
    ip6tables -P INPUT DROP
    ip6tables -P FORWARD DROP
    ip6tables -P OUTPUT DROP
    ip6tables -t mangle -P INPUT DROP
    ip6tables -t mangle -P OUTPUT DROP

    #Default policy
    iptables -t mangle -P INPUT ACCEPT
    iptables -t mangle -P OUTPUT ACCEPT
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT

    #Initial flush/deletes builtin chains
    iptables -F
    iptables -X
    iptables -t mangle -F
    iptables -t mangle -X

    #Loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    if [ $1 = "acidburn" ]; then
      in_ports="$p_ssh $p_vnc"
      for port in $in_ports
      do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        iptables -A OUTPUT -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      done
    elif [ $1 = "viral" ]; then
      in_ports="$p_ssh $p_smtp $p_imap $p_http $p_https"
      for port in $in_ports
      do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        iptables -A OUTPUT -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      done
    elif [ $1 = "anarchaos" ]; then
      in_ports="$p_ssh $p_es $p_http $p_https"
      for port in $in_ports
      do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        iptables -A OUTPUT -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      done
    #elif [ $1 = "pwnsauce" ]; then
      #in_ports="$p_ssh $p_http $p_https"
      #for port in $in_ports
      #do
        #iptables -A INPUT -p tcp --dport $port -j ACCEPT
        #iptables -A OUTPUT -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      #done
    #elif [ $1 = "kayla" ]; then
      #in_ports="$p_ssh $p_http $p_https"
      #for port in $in_ports
      #do
        #iptables -A INPUT -p tcp --dport $port -j ACCEPT
        #iptables -A OUTPUT -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      #done
    #elif [ $1 = "tflow" ]; then
      #in_ports="$p_ssh $p_http $p_https"
      #for port in $in_ports
      #do
        #iptables -A INPUT -p tcp --dport $port -j ACCEPT
        #iptables -A OUTPUT -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      #done
    else
      #when box is avuint
      in_ports="$p_ssh $p_xmpp"
      for port in $in_ports
      do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        iptables -A OUTPUT -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      done
    fi

    #Allow ping from inside to outside
    iptables -A OUTPUT -p icmp --icmp-type 8 -j ACCEPT
    iptables -A INPUT -p icmp --icmp-type 0 -j ACCEPT

    #Allow ping from outside to inside
    iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
    iptables -A OUTPUT -p icmp --icmp-type 0 -j ACCEPT

    #Drop otherwise
    iptables -A INPUT -j DROP
    iptables -A OUTPUT -j DROP

    #Test rules (comment line below to put rules in place)
    sleep 5 && ip -F
  fi
fi
