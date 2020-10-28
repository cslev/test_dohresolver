#!/bin/bash

mydir="$(dirname "$0")"
source $mydir/sources/extra.sh
 
 
function show_help 
 { 
 	c_print "Green" "This script uses curl --doh-url to test a DoH resolver"
 	c_print "Bold" "Example: ./test_dohresolver.sh -r <RESOLVER_URI> -d <DOMAIN>"
 	c_print "Bold" "\t\t-d <DOMAIN>: set the DOMAIN to resolve (Default: google.com)."
 	c_print "Bold" "\t\t-r <RESOLVER>: set RESOLVER's ID here from ./sources/r_config.json (Default: 1 (https://cloudflare-dns.com/dns-query))."
  c_print "Bold" "\t\t-l <FIRST_L_DOMAINS_FROM_ALEXA_LIST>: Define the number of domains from Alexa domain lists for testing. Use without -d (Default: Using the domain set by -d instead)."
 	exit
 }

DOMAIN=""
DEFAULT_DOMAIN="google.com"

RESOLVER_ID=""
DEFAULT_RESOLVER_URI="https://cloudflare-dns.com/dns-query"

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
 		RESOLVER_ID=$OPTARG
 		;;
 	l)
 		L=$OPTARG
 		;;     
 	*)
 		show_help
 		;;
 	esac
done





if [ -z $RESOLVER_ID ]
then
  c_print "Yellow" "No RESOLVER_URI is set, using default (${DEFAULT_RESOLVER_URI}))"
  RESOLVER_URI=$DEFAULT_RESOLVER_URI
# show_help
else
  
  #parse json object - we need jq for this --- install jq if you don't have it
  resolver=$(cat $mydir/sources/r_config.json |jq .|grep "\"id\": ${RESOLVER_ID}," -A 3|grep uri|cut -d ':' -f 2-|sed "s/\"//g"|sed "s/ //g"|sed "s/,//g")
  resolver_name=resolver=$(cat $mydir/sources/r_config.json |jq .|grep "\"id\": ${RESOLVER_ID}," -A 3|grep simple_name|cut -d ':' -f 2-|sed "s/\"//g"|sed "s/ //g"|sed "s/,//g")
  RESOLVER_URI=$resolver
  c_print "White" "Chosen resolver's URI: ${RESOLVER_URI}"
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


#get date
d=$(date +"%Y%m%d_%H%M%S")


D="http://${DOMAIN}"
R=$RESOLVER_URI

output_file="doh_res_${resolver_name}_${d}"

# rm curl_output 2&>1 /dev/null

# curl_cmd="curl -L --doh-url $R $D -m 10 -sS -w 'time_lookup:%{time_namelookup}\ntime_total:%{time_total}' 1>curl_output" 
#   time_namelookup:  %{time_namelookup}\n
#   time_connect:  %{time_connect}\n
#   time_appconnect:  %{time_appconnect}\n
#   time_pretransfer:  %{time_pretransfer}\n
#   time_redirect:  %{time_redirect}\n
#   time_starttransfer:  %{time_starttransfer}\n
#   ----------\n
#   time_total:  %{time_total}\n
# EOF"

if [ -z $L ]
then
  c_print "White" "Check $D via $R..."
  curl -sS -m 10 --doh-url $R $D 2>&1 > /dev/null
  # $curl_cmd
  retval=$(echo $?)
  MAP[$retval]=1

else
  j=0
  for i in $(cat $mydir/sources/top-1m.csv|head -n $L|cut -d ',' -f 2)
  do
    j=`expr $j + 1`
    D="http://${i}"
    echo "${j} -- ${D}"
    echo "${j} -- ${D}" >> $output_file
    curl -sS -m 10 --doh-url $R $D 2>&1 > /dev/null
    # $curl_cmd
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
  echo "Return code ${K}  --  ${MAP[$K]}" >> $output_file
done
