#!/bin/bash

# copy cert to syncthing folder for syncthing to use
cp -u /home/syncthing/example.com/cert.pem /home/syncthing/cert_nginx/cert.pem
cp -u /home/syncthing/example.com/privkey.pem /home/syncthing/cert_nginx/key.pem
cp -u /home/syncthing/example.com/chain.pem /home/syncthing/cert_nginx/ca-chain.pem

# send confirmation message to notification chat room
curl -X POST -H 'Content-Type: application/json' -d '{"text": "Nginx certs prepared."}' 'https://YOUR_CHAT_API/v2/YOUR_TOKEN'
