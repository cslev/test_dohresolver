#!/bin/bash

mydir="$(dirname "$0")"
source $mydir/sources/extra.sh

DEFAULT_NUM_DOMAINS=10000

function show_help
{
 	c_print "BGreen" "This script evaluates all resolvers stored in r_config.json file by using the helper script test_dohresolver.sh"
	c_print "BGreen" "It uses 'screen' for each testing and names the screens according to the resolver tested"
	c_print "Bold" "\t\t-l <FIRST_L_DOMAINS_FROM_ALEXA_LIST>: Define the number of domains from Alexa domain lists for testing (Default: 10,000)"
 	exit
}

NUM_DOMAINS=""

while getopts "h?l:" opt
 do
 	case "$opt" in
 	h|\?)
 		show_help
 		;;
 	l)
 		NUM_DOMAINS=$OPTARG
 		;;
 	*)
 		show_help
 		;;
 	esac
done


if [ -z $NUM_DOMAINS ]
 then
    c_print "Yellow" "No FIRST_L_DOMAINS_FROM_ALEXA_LIST is set, using default (${DEFAULT_NUM_DOMAINS}))"
    NUM_DOMAINS=$DEFAULT_NUM_DOMAINS
 fi


#iterate through all `id`
for i in $(cat $mydir/sources/r_config.json |grep "\"id\":"|cut -d ':' -f 2|sed "s/ //g"|sed "s/,//g")
do
  resolver_name=$(cat $mydir/sources/r_config.json |jq .|grep "\"id\": ${i}," -A 3|grep simple_name|cut -d ':' -f 2-|sed "s/\"//g"|sed "s/ //g"|sed "s/,//g")
  c_print "Initiaing 'screen' for resolver ${resolver_name}"
  screen -S ${resolver_name} -dm bash -c "time ./test_dohresolver.sh -r ${i} -l ${NUM_DOMAINS}; bash"

done
