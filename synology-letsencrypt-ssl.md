# Utilizing a Let's Encrypt SSL Cert on a Synology NAS
Synology requires a plugin to utilize Syncthing.


1. Go to Package Center and enable Community Packages
  - Settings > Package Sources > Add
  - Name: Synocommunity
  - URL: http://packages.synocommunity.com/
2. Click the Community tab that appears > search for & install Syncthing
3. Once installed, set the GUI username & password for Syncthing

***

### On the Synology box: Setup for Syncthing:
- Login to the machine via SSH:
```bash
ssh your_admin_name@yoursynologyboxhost
```

- Change into the directory where the default certs live
```bash
cd /usr/syno/etc/certificate/system/ && ls -l
```

- Change the permissions on the cert directory, so Syncthing's user can write to the `default` folder, where the certs live
```bash
chown sc-syncthing:root default/
```

- Make a backup of the native certs
```bash
cd default && mkdir certbackup &&
mv cert.pem certbackup/cert.pem &&
mv fullchain.pem certbackup/fullchain.pem &&
mv privkey.pem certbackup/privkey.pem &&
mv syno-ca-cert.pem certbackup/syno-ca-cert.pem
```

- After you initiate the share from the Cert server, a prompt should appear on the new Synology machine.
- If the share doesn’t appear, go into Remote Devices > Edit > Advanced > Addresses: change from dynamic to tcp://[your synology ip]:22000 *(the IP of the Synology box/destination server)*

### Required Options Before Hitting "Save" on the Connection from Your Cert Machine
- When your Synology's Syncthing accepts the share from your Cert server, make the **destination**: `/usr/syno/etc/certificate/system/default/`
- Advanced tab > Receive Only > Save
- Ignore tab:
```text
certbackup
syno-ca-cert.pem
```
- Save

The wildcard cert should appear shortly after.

## Setting up the Automation
- Log into the Synology admin, https://[your synology ip]:5001 and set up a task to restart nginx every week (that way, we don't need to code anything for forceful restarts after a cert update.)
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

## Improve Security (optional)
You can increase security by turning off broadcasting for the Synology box and modifying each of your endpoints to utilize a static IP instead of the default `dynamic` value.

- Caveat 1: You lose the third-party bridge/jump machines, which make inter-vlan detection super easy and not something you need to manage through your firewall
- Caveat 2: By turning off broadcasting, you lose the ease-of-use setup and must manually specify any new targets (they won't auto-detect your Synology any longer)
- By doing this approach, you'll also need to configure any governing appliance firewall rules accordingly to allow the inter-vlan traffic for the specified hosts

## Disable Broadcasts
1. Login to the Synology admin GUI
2. Head to **Control Panel**
3. Open **File Services**
4. Click the **Advanced** tab
5. *Untick* Enable Bonjour service discovery
6. *Untick* Enable Windows network discovery to allow access via web browsers

## Filtering Traffic to the Synology Firewall
1. Open up the Syncthing dashboard for your Synology box: `https://example.com:8384`
2. Under **Remote Devices**, select the **Edit** button for your certificate relayer machine
3. Click the **Advanced** tab
4. Under **Addresses**, change to the protocol and IP of your certificate relayer, like:
  ```bash
  tcp://127.0.0.1:22000
  ```
  - Note that firewall rules between these two machines must be operable in order for this to work effectively - if you filter incoming *and* outgoing traffic, specify the target IPs accordingly
5. Redo the above for any other endpoints your certificate deployment server needs to talk to

### Modifying the Synology Firewall
In v6 (at least), the firewall was **not on** by default, so your Synology box was open to every device on your network.

If this is not intended behavior, do the following:
- Open **Control Panel**
- If you don't see the *Security* option, click **Advanced Mode** in the upper-right
- Once **Security** is open, select the *Firewall* tab
- Under *Firewall Profile*, create a new one
- Once in, configure the rules by importance; ie. if you have both **Mac** and **Windows** clients using the same VLAN, you can do the following to allow mounted fileshares:
  - Create
  - Select from a list of built-in applications > Select
  - Click the *Protocol* heading to sort alpha-numeric: ^
  - Tick the following (if you allow them on your network)
  - AFP (not needed if your Mac clients are all using `smb://`)
  - CIFS (Windows shares)
  - Click OK
  - Under the *Source IP* section, put the VLAN & subnet your approved users work on
    - Action: `Allow`

Now, you need to make a rule so you can still access the GUI; assuming you have a static IP, of course.  If you do not, don't use the firewall or you'll be in for a world of hurt and finding  yourself locked out, after your DHCP lease expires.

For static IP admins:

  - Create
  - Select from a list of built-in applications > Select
  - Select the *Enabled* column for the following:
    - Ports: 5000 (dsm http)
    - Ports: 5001 (dsm https)
    - Ports: 8384 (syncthing)
    - Ports: 443 (https/web gui)
    - Ports: 22 (ssh)

- **Arrange the rules so that the All All All Deny** is the *very last* rule -- anything after will NOT be processed and you risk locking those user(s) out of the Synology.

Be sure to **Enable** the firewall after all of the rules are ready to your liking
