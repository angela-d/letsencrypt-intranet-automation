#!/bin/bash

#### adding and converting to dos certs to prtg ####
\cp /home/syncthing/example.com/cert.pem /home/syncthing/cert_prtg/prtg.crt && unix2dos /home/syncthing/cert_prtg/prtg.crt
\cp /home/syncthing/example.com/chain.pem /home/syncthing/cert_prtg/root.pem && unix2dos /home/syncthing/cert_prtg/root.pem
\cp /home/syncthing/example.com/privkey.pem /home/syncthing/cert_prtg/prtg.key && unix2dos /home/syncthing/cert_prtg/prtg.key

# send confirmation message to notification chat room
curl -X POST -H 'Content-Type: application/json' -d '{"text": "PRTG cert prepared."}' 'https://YOUR_CHAT_API/v2/YOUR_TOKEN'
