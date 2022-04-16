# #!/bin/bash
# result=$(/usr/bin/certbot renew --cert-name $1 --pre-hook "systemctl stop caddy" --post-hook "systemctl start caddy")
# send() {
# /root/mine/telegram/send_message.sh "$1"
# }
# if [[ $result == *"succeeded"* ]];then
#   sudo cp /etc/letsencrypt/live/$1/* /usr/local/etc/xray/ssl/  || export fault=1   # pay attention to domain ,may need change
#   chmod 644 /usr/local/etc/xray/ssl/* || export fault=1
#   systemctl restart xray
#   result=$(systemctl status xray.service | awk '/failed/{print 1}')
#   [[ -z $result ]] || export fault=1
#   [[ $fault = 1 ]] && send "$1 domain certificate renew succeeded,but something run after it failed" || send "$1 domain certificate renew succeeded!" 
# elif [[ $result == *"No renewals"* ]];then
#   send "$1 domain certificate do not need renew!"
# else
#   send "Something unexpected happened when trying to renew $1 domain certification! You need to check the log file."
# fi
#!/bin/bash
result=$(/usr/bin/certbot renew --cert-name $1 --pre-hook "systemctl stop caddy" --post-hook "systemctl start caddy")
send() {
/root/mine/telegram/send_message.sh "$1"
}
if [[ $result == *"succeeded"* ]];then
  send "$1 domain certificate renew succeeded!"
elif [[ $result == *"No renewals"* ]];then
  send "$1 domain certificate do not need renew!"
else
  send "Something unexpected happened when trying to renew $1 domain certification! You need to check the log file."
fi
sudo cp /etc/letsencrypt/live/$1/* /usr/local/etc/xray/ssl/  || export fault=1   # pay attention to domain ,may need change
chmod 644 /usr/local/etc/xray/ssl/* || export fault=1
systemctl restart xray
result=$(systemctl status xray.service | awk '/failed/{print 1}')
[[ -z $result ]] || export fault=1
[[ $fault = 1 ]] && send "something wrong happend when restart xray!" || send "xray restart succeed!"
