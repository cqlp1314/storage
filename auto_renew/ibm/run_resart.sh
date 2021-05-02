#!/bin/bash
cd ~/mine/ibm/
source restart.sh
terminate="trojan-go"
forever="trojan-r"
files=$(find . -name "inf*")
files=($files)
length=${#files[@]}
day=$(date +"%d")
#number=$(($day % 10))
for i in $(seq 1 $length);do
ibm_info inf${i}.txt
result=$(ibm_restart)
#echo "result :$result"

if [[ "$result" =~ "running" ]]
then
 if  [[ $day = 01 ]]
 then
   /home/ubuntu/mine/telegram/send_message.sh "ibm${i} restart succeeded!Account:${account},Appname:${appname} App:${!appname}"
 fi
else
 /home/ubuntu/mine/telegram/send_message.sh "ibm${i} restart failed!Account:${account},Appname:${appname} App:${!appname}"
fi
sleep 60
done
