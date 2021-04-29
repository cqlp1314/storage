#!/usr/bin/env /usr/bin/python3
import requests
import sys
import json
import os.path as path

def send_message(message):
    if path.exists("data.txt"):
        with open("data.txt","r") as json_file:
            data=json.load(json_file)
            bot_token=data['bot_token']
            bot_chatID=data['bot_chatID']
    else:
        bot_token=input("bot_token: ")
        bot_chatID=input("bot_chatID: ")
        data={}
        data['bot_token']=bot_token
        data['bot_chatID']=bot_chatID
        with open('data.txt','w') as outfile:
            json.dump(data,outfile)

 
    send_text = 'https://api.telegram.org/bot' + bot_token + '/sendMessage?chat_id=' + bot_chatID + '&parse_mode=Markdown&text=' + message
    response = requests.get(send_text)
    return response.json()
bot_message=sys.argv[1]
send_message(bot_message)
