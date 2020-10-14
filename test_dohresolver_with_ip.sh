#!/bin/bash

mydir="$(dirname "$0")"
source $mydir/sources/extra.sh
 
 
function show_help 
 { 
 	c_print "Green" "This script issues a test DoH query to a resolver. It can be used for several purposes, for instance, check whether a DoH resolver (identified by it URI) sits behind different IP addresses."
 	c_print "Bold" "Example: ./test_dohresolver_with_ip.sh -a 104.16.1.1 -d google.com -r https://mozilla.cloudflare-dns.com"
 	c_print "Bold" "\t\t-a <IP>: set IP/prefix of the DoH resolver (Default (cloudflare): 104.16.248.249)."
 	c_print "Bold" "\t\t-d <DOMAIN>: set the DOMAIN to resolve (Default: google.com)."
 	c_print "Bold" "\t\t-r <RESOLVER_URI>: set RESOLVER's URI (Default: https://mozilla.cloudflare-dns.com)."
 	exit
 }

IP="104.16.248.0/24"
DOMAIN=""
RESOLVER_URI=""


while getopts "h?a:d:r:" opt
 do
 	case "$opt" in
 	h|\?)
 		show_help
 		;;
 	a)
 		IP=$OPTARG
 		;;
 	d)
 		DOMAIN=$OPTARG
 		;;
 	r)
 		RESOLVER_URI=$OPTARG
 		;;
 
 	*)
 		show_help
 		;;
 	esac
 done


if [ -z $IP ]
 then
 	c_print "Yellow" "No IP is set, using default (${IP}))"
 	# show_help
 fi
 
 if [ -z $DOMAIN ]
 then
 	c_print "Yellow" "No DOMAIN is set, using default (${DOMAIN}))"
 	# show_help
 fi

 if [ -z $RESOLVER_URI ]
 then
 	c_print "Yellow" "No RESOLVER_URI is set, using default (${RESOLVER_URI}))"
 	# show_help
 fi



NETWORK=$(echo $IP | cut -d '/' -f 1)
PREFIX=$(echo $IP | cut -d '/' -f 2)
resolved=0
unresolved=0
c_print "White" "Resolving domain ${DOMAIN} using ${RESOLVER_URI}..." 

if [ "$PREFIX" == "24" ]
then
  IP_SUB=$(echo ${NETWORK} | cut -d '.' -f 1-3)
  for i in {1..255}
  do
    c_print "White" "Testing IP ${IP_SUB}.${i}..." 1
    curl -H 'accept: application/dns-json' --resolve mozilla.cloudflare-dns.com:443:${IP_SUB}.${i} 'https://mozilla.cloudflare-dns.com/dns-query?name=google.com&type=A' 2>&1 |grep "\"Status\":0" -q
    if [ $? -eq 0 ]
    then 
	  resolved=`expr $resolved + 1`
	  c_print "Green" "[SUCCESS]" 
    else
	  unresolved=`expr $unresolver + 1`
	  c_print "Red" "[FAIL]"
    fi 
  done
fi

if [ "$PREFIX" == "16" ]
then
  IP_SUB=$(echo ${NETWORK} | cut -d '.' -f 1-2)
  for i in {1..255}
  do
    for j in {1..255}
    do
      c_print "White" "Testing IP ${IP_SUB}.${i}.${j}..." 1
      curl -H 'accept: application/dns-json' --resolve mozilla.cloudflare-dns.com:443:${IP_SUB}.${i}.${j} 'https://mozilla.cloudflare-dns.com/dns-query?name=google.com&type=A' 2>&1 |grep "\"Status\":0" -q
      if [ $? -eq 0 ]
      then 
      resolved=`expr $resolved + 1`
      c_print "Green" "[SUCCESS]" 
      else
      unresolved=`expr $unresolver + 1`
      c_print "Red" "[FAIL]"
      fi 
    done
  done
fi


# c_print "Green" "\n"
c_print "Green" "\nResolved: ${resolved}"
c_print "Yellow" "Unresolved: ${unresolved}"


