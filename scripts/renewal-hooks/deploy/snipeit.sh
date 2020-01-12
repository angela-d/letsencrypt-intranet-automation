#!/bin/bash

# copy cert to snipeit
cp -u /home/syncthing/example.com/cert.pem /home/syncthing/cert_snipeit/cert.pem
cp -u /home/syncthing/example.com/privkey.pem /home/syncthing/cert_snipeit/key.pem
cp -u /home/syncthing/example.com/chain.pem /home/syncthing/cert_snipeit/ca-chain.pem

# send confirmation message to notification chat room
curl -X POST -H 'Content-Type: application/json' -d '{"text": "Snipeit certs prepared."}' 'https://YOUR_CHAT_API/v2/YOUR_TOKEN'
