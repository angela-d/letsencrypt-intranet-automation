# Using Syncthing on Debian/Ubuntu for Intranet SSL Propagation
After going through the initial setup on [Automating Wildcard SSL with Let's Encrypt](automating-letsencrypt-wildcard.md), now install Syncthing to propagate the wildcard certificate through the private network.

The following is for use on GNU/Linux-based servers in your private intranet network; those running Apache or Nginx services that are not on "the internet," for example.

Install dependencies
```bash
sudo apt update && sudo apt install curl supervisor apt-transport-https &&
curl -s https://syncthing.net/release-key.txt | sudo apt-key add - &&
echo "deb https://apt.syncthing.net/ syncthing stable" | tee /etc/apt/sources.list.d/syncthing.list &&
sudo apt update && apt install syncthing
```

Setup the Syncthing user
```bash
sudo adduser syncthing
```

Use systemd to auto-start Syncthing on system startup (Prefix = user, Suffix = service name)
```bash
sudo systemctl enable syncthing@syncthing.service
```

You should see:
> Created symlink /etc/systemd/system/multi-user.target.wants/syncthing@syncthing.service -> /lib/systemd/system/syncthing@.service.

Start Syncthing & create a directory for the certs to live:
```bash
sudo service syncthing@syncthing start && mkdir -p /home/syncthing/cert_assets && chown syncthing:syncthing /home/syncthing/cert_assets
```

**(optional)** If your preferred destination directory is owned by a user other than Syncthing, make it group-writable & add Syncthing to the owner's (directory) group
```bash
usermod -a -G git,syncthing syncthing
chmod g+rw -R git
```

Create a dummy file for **root** and back-date it (used to compare modified-time):
```bash
touch -d "5 hours ago" /home/lets_encrypt_mtime
```

Create a simple shell script to monitor the last modified time with the dummy file, at: `/home/monitor_letsencrypt` - Make sure it's executable:
```bash
touch /home/monitor-letsencrypt && chmod +x /home/monitor-letsencrypt && pico /home/monitor-letsencrypt
```

Populate `/home/monitor-letsencrypt` and modify the config paths to suit your environment:

*(There's a curl option for a hook to a chat service, if you use such a thing to get notifications.. uncomment if you use it, otherwise skip it)*
```bash
#!/bin/bash
# this will check the last modified time of /home/lets_encrypt_mtime and compare /home/syncthing

SYNCTHING="/home/syncthing/cert_assets/"
LETSENCRYPT="/home/lets_encrypt_mtime"

if test "$SYNCTHING" -nt "$LETSENCRYPT";
then

  # restart apache when the mtime is misaligned
  echo "New cert, Apache needs to restart!"
  /usr/sbin/service apache2 restart && echo "Apache restarted"
  touch "$LETSENCRYPT" && echo "Updated mtime file"
  #curl -X POST -H 'Content-Type: application/json' -d '{"text": "New cert detected - Apache restarted on Example server."}' 'https://YOUR_API_SERVICE/v2/...tokenkey goes here'
  echo "Done."

fi
```
*Note the fullpath to the service executable.  Without it, crontab doesn't know where to find it because no user env is invoked.*

Set up a cron via `sudo crontab -e`, **as root** to check every 30min for changes:
```bash
0,30 * * * * /home/monitor-letsencrypt
```

Since this is a Linux Server, we can do a tunnel to administer Syncthing's GUI (run this command on your local Linux/Mac PC, not the server)

This way, Syncthing's admin is not hanging around when we don't need it.  Not sure how to achieve the same in Windows.
```bash
ssh -N -L 8888:localhost:8384 angela@hostname-or-ip-of-server
```
- 8888 should be an unused port, this is the port the tunnel will listen on
- 8384 is the Syncthing port
- Once logged in (the terminal won't give any reply, it will "hang" - don't close it, minimize it), in your browser, go to: https://localhost:8888/ and you will see the Syncthing admin.

When you're done, hit CNTRL + C to terminate the tunnel.

## If Using an Apache Server
I prefer to make separate virtualhosts for http and https.

- Create a `sitename-ssl.conf`
- Populate with the following:
```bash
<VirtualHost *:443>
    SSLEngine On
    SSLCertificateFile /home/syncthing/cert_CHOSEN-NAME/cert.pem
    SSLCertificateKeyFile /home/syncthing/cert_CHOSEN-NAME/key.pem
    SSLCACertificateFile /home/syncthing/cert_CHOSEN-NAME/ca-chain.pem

    ServerAdmin youremail@example.com
    ServerName CHOSEN-NAME.example.com
    ServerAlias CHOSEN-NAME.example.com
    DocumentRoot /var/www/YOUR_INTRANET_SITE/
    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined
</VirtualHost>
```

- **SSLCertificate*** configs are relative to the paths of where the wildcard cert is kept locally
- **ServerName** & **ServerAlias** should reference the TLD
- **DocumentRoot** is where the `public_html` of the site is; most commonly `/var/www/sitename`

Enable SSL Apache module
```bash
sudo a2enmod ssl && service restart apache2
```

Enable the SSL site
```bash
sudo a2ensite [sitename]-ssl
```

- You should now see https://[sitename] in your browser.

Now enable the http version (so it can redirect to https, without mucking up the https config).
```bash
cd /etc/apache2/sites-available/000-default.conf && cp 000-default.conf [sitename].conf && pico [sitename].conf
```

Modify the following values to point to where the sitename-ssl.conf points:
```bash
ServerAdmin webmaster@example.com
DocumentRoot /var/www/html
```

Also add the following, from your -ssl.conf:
```bash
ServerAdmin youremail@example.com
ServerName CHOSEN-NAME.example.com
ServerAlias CHOSEN-NAME.example.com
DocumentRoot /var/www/YOUR_INTRANET_SITE/
```

Disable the default virtualhost (leaving this in-place can make troubleshooting an incorrectly setup vhost very difficult, as incorrect setups will load this as its 'proper' site):
```bash
a2dissite 000-default && service apache2 reload
```

If mod_rewrite is enabled, add this to the http virtualhost config, just before the closing /VirtualHost tag (less load than using it on .htaccess):
```bash
RewriteEngine On
RewriteCond %{HTTPS} !=on
RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]
```

- Run service apache2 restart after, http should now auto-redirect to https
