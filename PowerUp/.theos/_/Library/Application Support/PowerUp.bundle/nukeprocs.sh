#!/bin/bash
read -r -a array <<< $(ps ax -o pid= -o comm= | grep "/var/containers/Bundle/Application/\\|/Applications/" | grep -v grep | xargs | sed -r 's/ [^ ]*( |$)/\1/g');
for element in "${array[@]}";
do kill -9 $element; 
done;
unset array;