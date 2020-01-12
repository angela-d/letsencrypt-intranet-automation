# Utilizing a Let's Encrypt SSL Cert on a Synology NAS
Synology requires a plugin to utilize Syncthing.


1. Go to Package Center and enable Community Packages
2. Install Syncthing
3. Once installed, set the GUI username & password for Syncthing

***

### On the Synology box’s Syncthing:
- After you initiate the share from the Cert server, a prompt should appear on the new Synology machine.
- If the share doesn’t appear, go into Remote Devices > Edit > Advanced > Addresses: change from dynamic to tcp://[your synology ip]:22000 *(the IP of the Synology box/destination server)*
- When your Synology's Syncthing accepts the share from your Cert server, make the **destination**: `/usr/syno/etc/certificate/system/default/`

The wildcard cert should appear shortly after.

## Setting up the Automation
- Log into the Synology admin, https://[your synology ip]:5001 and set up a task to restart nginx every week (that way, we don'’'t need to code anything for forceful restarts after a cert update.)
- Set up a task to restart Nginx every week:
- Control Panel > Task Scheduler > Create > Scheduled Task > User-Defined Script:
  -  Task: Restart nginx for SSL
  -  User: root

**Under the Schedule tab:**

-  Run the following days: Sun

**Time**
-  First Run: 02:07
-  Frequency: Everyday (every Sunday)

**Task Settings**
- Run command > User-Defined Script:
```bash
synoservice --restart nginx
```
