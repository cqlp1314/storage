#!/usr/bin/env /usr/bin/python3
import requests
import sys

def send_message(message):
    bot_token=input("bot_token: ")
    bot_chatID=input("bot_chatID: ")
    send_text = 'https://api.telegram.org/bot' + bot_token + '/sendMessage?chat_id=' + bot_chatID + '&parse_mode=Markdown&text=' + message
    response = requests.get(send_text)
    return response.json()
bot_message=sys.argv[1]
send_message(bot_message)
