#!/bin/bash

# Trabalho realizado por:
# Rui Fernandes 		nMEC 92952
# Alexandre Rodrigues 	nMEC 92951

declare -A args=()
declare -A linesA=()
declare -A linesB=()
declare -A final_info=()
declare fileA=""
declare fileB=""
declare num_order_opts=0    #number of ordering options (-n -t -a -i)

parse_arguments () {
    while getopts ":rntai" opt; do
        case $opt in
            r)
            ;;
            n|t|a|i)
                if [[ num_order_opts -gt 0 ]]; then
                    echo "ERROR: too many ordering options, use only one of the following: -n -t -a -i"
                    exit
                fi
                num_order_opts=$((num_order_opts+1))
            ;;
            \?)
                echo "Invalid option: -$OPTARG"
                exit
                ;;
            *)
                echo "Option not implemented: -$OPTARG"
                exit
            ;;
        esac
        args[$opt]="$opt"
    done

    shift $((OPTIND - 1))
    if [[ -n "$@" ]]; then
        if [[ $# -ge 3 ]] || [[ $# -le 1 ]]; then
            echo "ERROR: The program requires exactly 2 files!"
            exit
        else
        	if [[ ! -f "$1" ]]; then
                echo "ERROR: file $1 not found!"
                exit
            fi
            if [[ ! -f "$2" ]]; then
                echo "ERROR: file $2 not found!"
                exit
            fi
            fileA="$1"
            fileB="$2"
        fi
    else
    	echo "ERROR: The program requires exactly 2 files!"
        exit
    fi
}

parse_arguments "$@"

while read lineA
   do 
   userA=$(echo $lineA  | awk '{print $1}') 
   linesA[$userA]=$lineA
        
done < $fileA

while read lineB
   do 
   userB=$(echo $lineB  | awk '{print $1}') 
   linesB[$userB]=$lineB

done < $fileB

for user in "${!linesA[@]}"
do
	if [[ ${linesB[$user]} ]]; then
		difSessoes=$(($(echo ${linesA[$user]} | awk '{print $2}') - $(echo ${linesB[$user]} | awk '{print $2}')))
		difTotalTime=$(($(echo ${linesA[$user]}  | awk '{print $3}') - $(echo ${linesB[$user]} | awk '{print $3}')))
        difMaxTime=$(($(echo ${linesA[$user]}  | awk '{print $4}') - $(echo ${linesB[$user]} | awk '{print $4}')))
        difMinTime=$(($(echo ${linesA[$user]}  | awk '{print $5}') - $(echo ${linesB[$user]} | awk '{print $5}')))
		final_info[$user]="$user  $difSessoes $difTotalTime $difMaxTime $difMinTime"
	else
		sessoesA=$(echo ${linesA[$user]} | awk '{print $2}') 
   		totalTimeA=$(echo ${linesA[$user]} | awk '{print $3}') 
   		maxTimeA=$(echo ${linesA[$user]} | awk '{print $4}') 
   		minTimeA=$(echo ${linesA[$user]} | awk '{print $5}') 
		final_info[$user]="$user  $sessoesA $totalTimeA $maxTimeA $minTimeA"
	fi
done

for user in "${!linesB[@]}"
do
	if [[ ! ${linesA[$user]} ]]; then
		difSessoes=$((0 - $(echo ${linesB[$user]} | awk '{print $2}')))
		difTotalTime=$((0 - $(echo ${linesB[$user]} | awk '{print $3}')))
        difMaxTime=$((0 - $(echo ${linesB[$user]} | awk '{print $4}')))
        difMinTime=$((0 - $(echo ${linesB[$user]} | awk '{print $5}')))
		final_info[$user]="$user $difSessoes $difTotalTime $difMaxTime $difMinTime"
	fi
done


order=""
if [[ ${args['r']} ]]; then
    order="r"
fi

if [[ ${args['n']} ]]; then
    printf "%s\n" "${final_info[@]}" | sort -k2,2n$order
elif [[ ${args['t']} ]]; then
    printf "%s\n" "${final_info[@]}" | sort -k3,3n$order
elif [[ ${args['a']} ]]; then
    printf "%s\n" "${final_info[@]}" | sort -k4,4n$order
elif [[ ${args['i']} ]]; then
    printf "%s\n" "${final_info[@]}" | sort -k5,5n$order
else
    printf "%s\n" "${final_info[@]}" | sort -k1,1$order
fi