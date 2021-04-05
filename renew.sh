#!/bin/bash
result=$(/usr/bin/certbot renew --pre-hook "systemctl stop caddy" --post-hook "systemctl start caddy")
if [[ $result == *"succeeded"* ]];then
  /root/mine/telegram/send_message.sh "$1 domain certificate renew succeeded!"
  cp /etc/letsencrypt/live/$domain/* /usr/local/etc/xray/ssl/
  systemctl restart xray
elif [[ $result == *"No renewals"* ]];then
  /root/mine/telegram/send_message.sh "$1 domain certificate do not need renew!"
else
  /root/mine/telegram/send_message.sh "Something unexpected happened when trying to renew $1 domain certification! You need to check the log file."
fi
