#!/bin/bash

#### adding certs to synology
\cp /home/syncthing/example.com/fullchain.pem /home/syncthing/cert_synology/fullchain.pem &&
\cp /home/syncthing/example.com/chain.pem /home/syncthing/cert_synology/chain.pem &&
\cp /home/syncthing/example.com/privkey.pem /home/syncthing/cert_synology/privkey.pem &&
\cp /home/syncthing/example.com/cert.pem /home/syncthing/cert_synology/cert.pem

# send confirmation message to notification chat room
curl -X POST -H 'Content-Type: application/json' -d '{"text": "Synology certs prepared."}' 'https://YOUR_CHAT_API/v2/YOUR_TOKEN'
