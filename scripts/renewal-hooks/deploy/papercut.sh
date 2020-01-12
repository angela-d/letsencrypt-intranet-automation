#!/bin/bash

#### adding and converting to dos certs to prtg ####
\cp /home/syncthing/example.com/cert.pem /home/syncthing/cert_papercut/cert.pem
\cp /home/syncthing/example.com/chain.pem /home/syncthing/cert_papercut/chain.pem
\cp /home/syncthing/example.com/privkey.pem /home/syncthing/cert_papercut/privkey.pem

# make a pfx for import to the ms cert store
openssl pkcs12 -export -out /home/syncthing/cert_papercut/papercut-certificate.pfx -inkey /home/syncthing/cert_papercut/privkey.pem -in /home/syncthing/cert_papercut/cert.pem -certfile /home/syncthing/cert_papercut/chain.pem -passin pass: -passout pass:

# send confirmation message to notification chat room
curl -X POST -H 'Content-Type: application/json' -d '{"text": "Papercut certs prepared."}' 'https://YOUR_CHAT_API/v2/YOUR_TOKEN'
