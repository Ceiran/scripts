#!/bin/bash
#box names
boxes="williamkidd calicojack canoot nemo gunner laurellabonaire"
#Ports
p_ssh="22"
p_http="80"
p_https="443"
p_ftp="21"
p_ssl="990"
p_sql="1433 4022 135 1434 139 445 5022 7022"
p_sqludp="137 138 1434"
p_nginx="80 443"
# docker also requires ssh
p_docker="2376 2377 7946"
p_dockerudp="7946 4789"
# flask also requires http and https
p_flask="5000"

#Check to see if positional parameter 1 exists
match="no"
if [ -z "$1" ]; then
  echo "Positional parameter 1 is empty. Please enter a box name."
else
  for name in $boxes
  do
    if [ $1 = $name ]; then
      match="yes"
      if [ $1 = "calicojack" ]; then
        firewall-cmd --set-default-zone=public

        in_ports="$p_ssh $p_sql $p_ftp $p_http $p_https"
        for port in $in_ports
        do
          firewall-cmd --permanent --add-port=$port/tcp
        done
        for port in $p_sqludp
        do
          firewall-cmd --permanent --add-port=$port/udp
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

    if [ $1 = "williamkidd" ]; then
      in_ports="$p_ssh $p_ftp $p_ssl $p_http $p_https"
      for port in $in_ports
      do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        iptables -A OUTPUT -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      done
    elif [ $1 = "calicojack" ]; then
      in_ports="$p_ssh $p_sql"
      for port in $in_ports
      do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        iptables -A OUTPUT -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      done
      for port in $p_sqludp
      do
        iptables -A INPUT -p udp --dport $port -j ACCEPT
        iptables -A OUTPUT -p udp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      done
    elif [ $1 = "canoot" ]; then
      in_ports="$p_ssh"
      for port in $in_ports
      do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        iptables -A OUTPUT -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      done
    elif [ $1 = "nemo" ]; then
      in_ports="$p_ssh $p_nginx"
      for port in $in_ports
      do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        iptables -A OUTPUT -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      done
    elif [ $1 = "gunner" ]; then
      in_ports="$p_ssh $p_docker"
      for port in $in_ports
      do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        iptables -A OUTPUT -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      done
      for port in $p_dockerudp
      do
        iptables -A INPUT -p udp --dport $port -j ACCEPT
        iptables -A OUTPUT -p udp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT
      done
    else
      #when box is laurellabonaire
      in_ports="$p_ssh $p_flask $p_http $p_https"
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
