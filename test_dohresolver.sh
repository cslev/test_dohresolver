#!/bin/bash

mydir="$(dirname "$0")"
source $mydir/sources/extra.sh
 
 
function show_help 
 { 
 	c_print "Green" "This script uses curl --doh-url to test a DoH resolver"
 	c_print "Bold" "Example: ./test_dohresolver.sh -r <RESOLVER_URI> -d <DOMAIN>"
 	c_print "Bold" "\t\t-d <DOMAIN>: set the DOMAIN to resolve (Default: google.com)."
 	c_print "Bold" "\t\t-r <RESOLVER_URI>: set RESOLVER's URI (Default: https://mozilla.cloudflare-dns.com/dns-query)."
  c_print "Bold" "\t\t-l <FIRST_L_DOMAINS_FROM_ALEXA_LIST>: Define the number of domains from Alexa domain lists for testing. Use without -d (Default: Using the domain set by -d instead)."
 	exit
 }

DOMAIN=""
DEFAULT_DOMAIN="google.com"

RESOLVER_URI=""
DEFAULT_RESOLVER_URI="https://mozilla.cloudflare-dns.com/dns-query"

L=""

declare -A ERRORS


while getopts "h?d:r:l:" opt
 do
 	case "$opt" in
 	h|\?)
 		show_help
 		;;
 	d)
 		DOMAIN=$OPTARG
 		;;
 	r)
 		RESOLVER_URI=$OPTARG
 		;;
 	l)
 		L=$OPTARG
 		;;     
 	*)
 		show_help
 		;;
 	esac
done


if [ -z $RESOLVER_URI ]
then
  c_print "Yellow" "No RESOLVER_URI is set, using default (${DEFAULT_RESOLVER_URI}))"
  RESOLVER_URI=$DEFAULT_RESOLVER_URI
# show_help
fi

if [ -z $DOMAIN ]
then
  c_print "Yellow" "No DOMAIN is set, using default (${DEFAULT_DOMAIN}))"
 	# show_help
  DOMAIN=$DEFAULT_DOMAIN
fi



if [ -z $L ]
 then
   c_print "Yellow" "No FIRST_L_DOMAINS_FROM_ALEXA_LIST is set, using domain set by -d argument (${DOMAIN}))"
 	# show_help
 fi



D="http://${DOMAIN}"
R=$RESOLVER_URI


if [ -z $L ]
then
  c_print "White" "Check $D via $R..."
  curl -sS -m 10 --doh-url $R $D 1>curl_output
  retval=$(echo $?)
  MAP[$retval]=1

else
  j=0
  for i in $(cat $mydir/sources/top-1m.csv|head -n $L|cut -d ',' -f 2)
  do
    j=`expr $j + 1`
    D="http://${i}"
    echo "${j} -- ${D}"
    curl -sS -m 10 --doh-url $R $D 1>curl_output
    retval=$(echo $?)

    #check if retval is already in the hashmap
    if [ ${MAP[$retval]+_} ]
    then
      #key exists, update value
      MAP[$retval]=`expr ${MAP[$retval]} + 1`
    else
      MAP[$retval]=1
    fi
  done
fi

#printing out error code stats
c_print "White" "Return value statistics:"
for K in ${!MAP[@]}
do 
  echo "Return code ${K}  --  ${MAP[$K]}" 
done
