#!/bin/bash
cd ~/mine/ibm/
source restart.sh

write_inf_file() {
cat > inf${index}.txt <<-EOF
region:$region
account:$account
passwd:$passwd
appname:$appname
EOF
}


create_file() {
continue_="yes"
index=0

while [ $continue_ == "yes" ]
do
  index=$(( index + 1 ))
  read -p 'region(us-south): ' region
  read -p 'account: ' account
  read -p 'passwd: ' passwd
  read -p 'appname: ' appname
  read -p 'platform(xray): ' platform
  write_inf_file
  read -p 'continue or not,if continue,enter yes,otherwise enter no: ' continue_
done
}


[[ ! -f inf1.txt ]] && echo "Please enter information,you can create multiple account according tips." && create_file 

files=$(find . -name "inf*")  #inf file includes region,account,passwd,appname four lines.
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
   ~/mine/telegram/send_message.sh "ibm${i} restart succeeded!Account:${account},Appname:${appname} App:${platform}"
 fi
else
 ~/mine/telegram/send_message.sh "ibm${i} restart failed!Account:${account},Appname:${appname} App:${platform}"
fi
sleep 60
done
