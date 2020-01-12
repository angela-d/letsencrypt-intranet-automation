Import-Module pswatch

# config needs work.  escaping the & in the uri proved difficult with ps.

# these should eventually be imported by a config script on the server
# change to suit your server.. i left mine as an example
# Chat-Post function leaves a message on a chat service used for notifications.  remove references if not in use
$server                = "PRTG"
$watchDir              = "C:\Program` Files` `(x86`)\PRTG` Network` Monitor\cert"
$Message               = "Certs updated in PRTG, at"
$restartService        = "PRTGCoreService"
$restartServiceDepends = "PRTGProbeService"
$chatPost              = $Message + ' ' + $((Get-Date).ToString())



function Check-ServiceStats($service) {

	if (Get-Service $service -ErrorAction SilentlyContinue) {

		$serviceStatus = (Get-Service -Name $service).Status
		Write-Output $serviceStatus

	} else {

		Write-Output "$service not found or is not running!"

	}
}


function Stagger-Restart($service, $server) {

	# sleep and then restart
	Start-Sleep -s 10
	Restart-Serv $service $server

}


function Restart-Serv($serviceName, $server) {

  if ((Get-Service -Name $serviceName).Status -eq 'Running') {

    Chat-Post "Preparing to restart $serviceName on $server..."
    Get-Service -Name $serviceName | Stop-Service -ErrorAction SilentlyContinue
    Get-Service -Name $serviceName | Start-Service -ErrorAction SilentlyContinue

    Start-Sleep -s 3
    $serviceStatus = Check-ServiceStats $serviceName


    if ($serviceStatus -eq 'Running') {

      Chat-Post "$serviceName on $server is running; restart complete."

    } else {

      Chat-Post "ERROR: $serviceName on $server might not be running, you should probably check on it!"

    }

  } else {

    Chat-Post "$serviceName was not running on $server, you should probably check on it!"

  }
}


function Chat-Post($message) {
  # comment out the lines below if you don't use a chat service for notifications

  # by default, powershell seems to want to use insecure/deprecated tls, the following fixes that
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  $postMessage = @{ text = "$message"; } | ConvertTo-Json

  Invoke-RestMethod -Method Post -Headers @{"Content-Type" = 'Application/json; charset=UTF-8'} -Uri 'https://YOUR_CHAT_API/v2/YOUR_TOKEN' -Body $postMessage

}
