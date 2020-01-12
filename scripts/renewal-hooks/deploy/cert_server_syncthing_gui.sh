#!/bin/bash

#### adding certs to syncthing gui ####

# copy cert to syncthing folder for syncthing to use
cp -u /home/syncthing/example.com/cert.pem /home/syncthing/.config/syncthing/https-cert.pem
cp -u /home/syncthing/example.com/privkey.pem /home/syncthing/.config/syncthing/https-key.pem

# restart syncnthing here, after new cert installed
supervisorctl restart syncthing

# send confirmation message to notification chat room
curl -X POST -H 'Content-Type: application/json' -d '{"text": "Syncthing cert prepared."}' 'https://YOUR_CHAT_API/v2/YOUR_TOKEN'
