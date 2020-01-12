# Windows Setup for Syncthing and Let's Encrypt SSL
The Windows side seems a bit buggy - the Syncthing service seems to turn itself off the day prior to the certificate dispersal and I've not yet had a chance to troubleshoot it.

### Steps
1. Install NSSM (to easily create Windows services)
2. Clone your customized Certwatch script from your private git repo (Certwatch will restart the http server when a new cert is detected)
3. Install PSWatch (dependency of Certwatch)
4. Add the git hook to the repo's .git/hooks/post-merge file (auto-restart Certwatch after changes to your config are made)
5. Setup the config on Certwatch

## Install NSSM, Syncthing & Git to your Windows Server
This allows you to easily setup the Certwatch executable.

1. Download from https://nssm.cc/download (I used nssm 2.24-101-g897c7ad (2017-04-26), if there's something newer, see if its better)
2. Unzip nssm-2.24-101-g897c7ad.zip and navigate to C:\nssm-2.24-101-g897c7ad\win64 - you'll see nssm.exe > copy nssm.exe to C:\Windows -- this adds it to %PATH% so we don't need to specify its path when trying to run it via CLI or script.
3. Install Syncthing for Windows: https://github.com/syncthing/syncthing/releases

## Install Syncthing
Download Syncthing
- Download from Github: https://github.com/syncthing/syncthing/releases/latest to `C:\Program Files\Syncthing`
- Run nssm install syncthing and configure it as an automatic service (then start the service)
- Accessible via web GUI at http://127.0.0.1:8384/

## Setup Syncthing as a Windows Service
Open Powershell and run the following
```powershell
nssm install Syncthing
```
In the triggered window popup:
- Can run as Local User
- Set a password: Actions > Settings > GUI Authentication > tick Use HTTPS for GUI
- Needs to be manually started for the first time (not sure of the argument to pass when creating it to trigger a start)

**Sync the Cert Folder**
- Actions → Show ID (host you want to sync to) > copy to your Cert server's Syncthing dashboard
- (On your Cert server) + Add Remote Device
- (On your Cert Server)+ Add Folder > Specify the folder from /home/syncthing/ in the Folder Label field
- On the Sharing tab > tick the server you just added > Save

Takes a few minutes, but eventually the Cert server will invite its folder to the Windows server.  Don't add it manually, wait for the invite to appear on the dashboard.

Once the message appears, click Add > General tab: change the Folder Path to `C:\letsencrypt` (create it) > Advanced tab: Folder Type: Receive Only

## Install Git for Windows
Git for Windows: https://git-scm.com/download/win


## Generate an SSH Key for Git
This will be used to grab a copy of Certwatch from your private repo
- Login to the administrator account (since it's the only one guaranteed to never be moved, renamed or lost if the domain trust fails)
- In Git Bash (not cmd or Powershell -- `C:\Program Files\Git\git-bash.exe`), run:
```bash
ssh-keygen -t rsa -b 4096
```
1. Save to its default `c/Users/Administrator/.ssh/id_rsa` location
2. Hit enter (empty passphrase)
3. Hit enter again to confirm
4. Add the pubkey to your private git repo where your customized version of Certwatch will live

## Clone Certwatch to Your Private Repo
- Clone windows-certwatch **in `C:\`** -- `git clone https://yourprivategitrepo.git Certwatch` – the Certwatch reference after the clone URL instructs git to 'rename' the destination.  No path means it'll clone to the repo name in the directory your CLI is focused in.  

You want the final destination to be: C:\Certwatch

Open `watch.ps1` and change any necessary config variables.  

Anything changed in `watch.ps1` means you'll either lose them or have to revert if you try to pull at any point in the future.  The config should eventually be moved to a standalone file outside of the git repo at some point. (Which is the entire purpose of setting up git, for the time being)

## Setup the Git hook to Activate Certwatch
The git hook processes after the Certwatch script is updated.  It works at this time, but once you modify the script its nullified -- end goal is to keep the config outside of the repo or in an ignored file.  So do this to future-proof:

In `.git/hooks/post-merge` (create if it doesn't exist), add:
```bash
#!C:/Program\ Files/Git/usr/bin/sh.exe
echo
exec powershell.exe -NoProfile -ExecutionPolicy Bypass Restart-Service -Name Certwatch
exit
```
This allows git to run a shell script that launches Powershell to restart a service, in this case, that service is what is powered by the script in this very repo.

## Install PSWatch
The dev offers a freaking bitly link (which is terrible and a potential security risk for MITM) – go to this URL in your browser and analyze the script, make sure no shady stuff is going on. (I tried to install from the github URL, but PS has questionable support out of the box for https - might work to make it non-https?  The script should be analyzed, anyway)...  If it looks good, proceed:

Open an elevated Powershell terminal and run:
```powershell
iex ((new-object net.webclient).DownloadString("http://bit.ly/Install-PsWatch"))
```

## Create the Certwatch Executable
In Powershell:
```bash
$nssm = (Get-Command nssm).Source
$serviceName = 'Certwatch'
$powershell = (Get-Command powershell).Source
$arguments = '-ExecutionPolicy Bypass -NoProfile -File C:/Certwatch/watch.ps1'
& $nssm install $serviceName $powershell $arguments
& $nssm status $serviceName
Start-Service $serviceName
Get-Service $serviceName
```

It will say Paused - because for some reason will not launch under local permissions and requires Administrator - another fix for later.

Set logging preferences:
```powershell
nssm set Certwatch AppStdout "C:\Logs\certwatch.log"
nssm set Certwatch AppRotateFiles 1
```

NSSM adds a registry key to HKLM\System\CurrentControlSet\Services\Certwatch – future changes can be made there or the Services app on Windows.

Set Launch permissions for Admin:
- Services > right-click on Certwatch > Log On tab:
- Select This Account > Browse.. > find the Administrator account > OK > enter the password

**Changes to Certwatch / watch.ps1 are not reflected until the Certwatch service is restarted (that's what the git hook is for)**
