#!/bin/bash

# Trabalho realizado por:
# Rui Fernandes         nMEC 92952
# Alexandre Rodrigues   nMEC 92951

declare -A users=()     #All users
declare -A args=()      #Global arguments array
declare times=()        #Array for use in calcTime()
declare -A info=()      #Associative array with users as keys and the relevant info as values
declare init_date=19700101010000    #Initial date
declare final_date=50000101010000   #Final date
declare num_order_opts=0            #number of ordering options (-n -t -a -i)


argForm() {
    if [[ $1 =~ -.* ]]; then
        echo "ERROR: argument format not valid"
        exit
    fi
}

parse_arguments () {
    while getopts ":rntaig:u:f:s:e:" opt; do
        case $opt in
            r)
                argForm "$OPTARG"
            ;;
            n|t|a|i)
                argForm "$OPTARG"
                if [[ num_order_opts -gt 0 ]]; then
                    echo "ERROR: too many ordering options, use only one of the following: -n -t -a -i"
                    exit
                fi
                num_order_opts=$((num_order_opts+1))
            ;;
            u|g)
                argForm "$OPTARG"
            ;;
            f)
                argForm "$OPTARG"

                if [[ ! -f "$OPTARG" ]]; then
                    echo "ERROR: file not found!"
                    exit
                fi
            ;;
            s|e)
                argForm "$OPTARG"

                # converts argument date to number of seconds since 1970-01-01 00:00:00 UTC
                OPTARG=$(date -d "$OPTARG" +%s)

            ;;
            \?)
                echo "ERROR: invalid option: -$OPTARG"
                exit
                ;;
            :)
                echo "ERROR: option -$OPTARG needs an argument."
                exit
                ;;
            *)
                echo "ERROR: option not implemented: -$OPTARG"
                exit
            ;;
        esac
        if [[ $OPTARG == "" ]]; then
            args[$opt]="$opt"
        else
            args[$opt]=$OPTARG # save all options in array
        fi
    done

    shift $((OPTIND - 1))
    if [[ -n "$@" ]]; then
        echo "ERROR: parameters are not valid: $@"
        exit
    fi
}

function calcTime(){
            t=$1

            if (( ${#t} == 5 )); then
                
                mins=$(echo $t | awk -F: '{ print ($1 * 60) + $2}')
                times[t_index]=$mins
                total_time=$(($total_time + $mins))
            
            else
                mins=$(echo $t | tr '+' ':' | awk -F: '{ print ($1 * 1440) + ($2 * 60) + $3}')
                times[t_index]=$mins
                total_time=$(($total_time + $mins))
            fi
}


function getUsers() {

    if [[ ${args['f']} ]]; then
        users=$(last -f ${args['f']} -s "$init_date" -t "$final_date" | awk '{print $1}' | sort -u | head -n -1 | sort | sed '/reboot/d' | sed "/${args['f']}/d" |grep -v '^$'z1)
    else
        users=$(last -s "$init_date" -t "$final_date" | awk '{print $1}' | sort -u | head -n -1 | sort |sed '/reboot/d' | sed '/wtmp/d'|grep -v '^$'z1)
    fi

    users=$(echo $users| tr " " "\n")
}

function getInfo() {
    for user in $users
    do
        if [[ ${args['f']} ]]; then
            time=$(last -f ${args['f']} -s "$init_date" -t "$final_date" | grep $user | awk '{print $10}' | sed '/in/d' | sed 's/[)(]//g' ) 
            session=$(last -f ${args['f']} -s "$init_date" -t "$final_date" | awk '{print $1}' | grep $user | wc -l)
        else
            time=$(last -s "$init_date" -t "$final_date" | grep $user | awk '{print $10}'  |sed '/in/d' | sed 's/[)(]//g') 
            session=$(last -s "$init_date" -t "$final_date" | awk '{print $1}' | grep $user | wc -l)
        fi
        
        total_time=0
        t_index=0
        for t in $time; do
            calcTime "$t"
            t_index=$((t_index+1))
        done
        IFS=$'\n'
        max_time=$(echo "${times[*]}" | sort -nr | head -n1)
        min_time=$(echo "${times[*]}" | sort -nr | tail -1)
        info[$user]="$user $session $total_time $max_time $min_time" 
        unset times #destroi array para o proximo user
     
    done
    unset times #array fica livre
}


function printInfo() {

    if [[ ${args['u']} ]]; then
        for user in $users; do
            if [[ ! $user =~ ${args['u']} ]]; then
                unset info[$user]
            fi
        done
    fi

    if [[ ${args['g']} ]]; then
        for user in $users; do
            if  ! (id -nG "$user" | grep -qw "${args['g']}"); then
                unset info[$user]
            fi
        done
    fi

    order=""
    if [[ ${args['r']} ]]; then
        order="r"
    fi

    if [[ ${args['n']} ]]; then
        printf "%s\n" "${info[@]}" | sort -k2,2n$order
    elif [[ ${args['t']} ]]; then
        printf "%s\n" "${info[@]}" | sort -k3,3n$order
    elif [[ ${args['a']} ]]; then
        printf "%s\n" "${info[@]}" | sort -k4,4n$order
    elif [[ ${args['i']} ]]; then
        printf "%s\n" "${info[@]}" | sort -k5,5n$order
    else
        printf "%s\n" "${info[@]}" | sort -k1,1$order
    fi
}

parse_arguments "$@"

if [[ ${args['s']} ]]; then
    init_date=$(date --date=@${args['s']} "+%Y%m%d%H%M%S")
fi
if [[ ${args['e']} ]]; then
    final_date=$(date --date=@${args['e']} "+%Y%m%d%H%M%S")
fi
getUsers
getInfo
printInfo