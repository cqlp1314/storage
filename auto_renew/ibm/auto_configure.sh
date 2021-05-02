#!/bin/bash
mkdir ~/mine/telegram/ ~/mine/ibm/
wget -O ~/mine/ibm/restart.sh https://github.com/cqlp1314/storage/raw/main/auto_renew/ibm/restart.sh
wget -O ~/mine/ibm/run_restart.sh https://github.com/cqlp1314/storage/raw/main/auto_renew/ibm/run_restart.sh
wget -O ~/mine/telegram/send_message.sh https://github.com/cqlp1314/storage/raw/main/send_message.sh

chmod +x restart.sh run_restart.sh ~/mine/telegram/send_message.sh

~/mine/ibm/run_restart.sh

(crontab -l 2>/dev/null;echo "2 0 5,20 * * cd ~/mine/ibm/; ./run_restart.sh > log.txt 2>&1")|crontab -
