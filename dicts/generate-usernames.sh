#!/usr/bin/env bash

usage(){
    echo "bash $(basename $0) <username>"
}

[ -z $1 ] && usage && exit 1

username=$1
script_dir=$(cd $(dirname $0) && pwd)
muban="${script_dir}/muban.key"

cat $muban|sed 's/%user%/'$username'/g'
