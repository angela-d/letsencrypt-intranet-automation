# Let's Encrypt Intranet Automation for Wildcard SSL
This is more of a documentation repo, as opposed to scripting, as no environment will be exactly the same.  This also isn't something that's typically done more than once, negating the need for a 'setup script.'

There's *many* different ways this can be done, if you know of a more efficient way, please share!!

[acme.sh](https://github.com/Neilpang/acme.sh) being another method of achieving SSL automation.

- Currently, Let's Encrypt doesn't offer certs to sites without public-facing DNS.  There's a lot of situations where you wouldn't want to place sensitive domains in DNS and even just opening port 80  for Let's Encrypt could reveal 'too much info,' by just advertising the existence of these subdomains.

- To circumvent this, set up an internal, non-public-facing Debian server that will handle all SSL certificate transactions for all of the internal sites.

- I also have a separate *public-facing* server running BIND for DNS, that handles the public side of things. I will base my notes off of this, assuming your environment will be the same.

Adjust things for your environment as you see fit!

### Topology
- DNS server (Ubuntu or Debian) - **public facing**
- Cert server (distributor) obtains a wildcard SSL from a parent domain referenced in DNS server (Ubuntu or Debian) - **internal**
- Internal servers receive certs from Cert server via Syncthing
- All internal sites utilize a subdomain, so a **wildcard cert** is issued to them; allowing all to use the same certificate

1. [Initial setup with the DNS & Cert servers](automating-letsencrypt-wildcard.md) - Public-facing DNS + distributor server steup

### Optional, Environment-Specific Setups
1. [Syncthing on Debian](syncthing-debian-propagation.md) - Notes for Linux-based http intranet server setups
2. [NPS/Radius](letsencrypt-radius-nps.md) - Network policy SSL for wifi authentication
3. [Synology](synology-letsencrypt-ssl.md) - https cert for the Synology NAS
4. [Windows](syncthing-windows.md) - Getting certs onto a Windows machine via Syncthing, from the Cert server

### Post-renewal Hooks on the Cert server
After your Cert server is setup, you can put your hook scripts in `/etc/letsencrypt/renewal-hooks`

I left a sample of popular applications like Synology, Snipeit, PRTG and Papercut in [scripts/renewal-hooks/deploy](scripts/renewal-hooks/deploy)

In modern versions of certbot on Ubuntu/Debian, you don't need to specify the post-renewal hooks in your `certbot renew` cron, just the presence of scripts in this directory should see them run after a successful renewal.

The post-renewal scripts will take a copy of the **live** certificate created by Let's Encrypt, rename & convert (if necessary) for its destination server.

## Potential Bugs after Setup
Depending on your naming scheme for the `/etc/letsencrypt/renewal-hooks/deploy` scripts, if the primary cert directory you're pulling from (ie. `/home/syncthing/example.com/` if you go by the [nginx](https://github.com/angela-d/letsencrypt-intranet-automation/blob/master/scripts/renewal-hooks/deploy/nginx.sh) example) doesn't get updated **before** nginx.sh runs, you'll run into a chicken and egg situation; so you'll want to ensure the renewal scripts are ordered accordingly.. something like 01-primary.sh, 02-nginx.sh)

An alternative approach is to simply copy from `/etc/letsencrypt/live/example.com/cert.pem` and so on.
