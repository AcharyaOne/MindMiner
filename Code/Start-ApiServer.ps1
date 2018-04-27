<#
MindMiner  Copyright (C) 2018  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

# https://learn-powershell.net/2013/04/19/sharing-variables-and-live-objects-between-powershell-runspaces/

. .\Code\Config.ps1

function Start-ApiServer {
	$global:API.Running = $true
	$global:API.Port = [Config]::ApiPort
	$global:API.Version = [Config]::Version
	$global:ApiListner = [Net.HttpListener]::new()
	$global:ApiRunSpace = [runspacefactory]::CreateRunspace()
	$global:ApiRunSpace.Open()
	$global:ApiRunSpace.SessionStateProxy.SetVariable("API", $global:API)
	$global:ApiRunSpace.SessionStateProxy.SetVariable("listner", $global:ApiListner)
	$global:ApiPowerShell = [powershell]::Create()
	$global:ApiPowerShell.Runspace = $ApiRunSpace
	$global:ApiPowerShell.AddScript({
		try {
			$listner.Prefixes.Add("http://localhost:$($API.Port)/")
			if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
				$listner.Prefixes.Add("http://+:$($API.Port)/")
			}
			$listner.Start()
			while ($API.Running -and $listner.IsListening) {
				try {
					$context = $listner.GetContext()
					$request = $context.Request

					$contenttype = "application/json"
					$statuscode = 200
					$content = $null

					$local = if ($context.Request.Url.LocalPath) { $context.Request.Url.LocalPath.ToLower() } else { [string]::Empty }

					switch ($local) {
						"/" {
							$contenttype = "text/html"
							$mm = "MindMiner $($API.Version) - $($API.Worker)"
							$config = if ($API.Config) { "<h2>Configuration</h2>" + $API.Config } else { [string]::Empty }
							$am = if ($API.MinersRunning) { "<h2>Active Miners</h2>" + $API.MinersRunning } else { [string]::Empty }
							$balance =  if ($API.Balance) { "<h2>Balance</h2>" + $API.Balance } else { [string]::Empty }
							$info =  if ($API.Info) { "<h2>Information</h2>" + $API.Info } else { [string]::Empty }
							$content = "<html><head><meta charset=`"utf-8`"><style>body { font-family: consolas }</style><title>$mm</title></head><body><h1>$mm</h1>" +
								$config + $am + $balance + $info + "</body></html>"
							Remove-Variable info, balance, am, config, mm
						}
						"/pools" {
							$content = $API.Pools | ConvertTo-Json
						}
						default {
							$statuscode = 404
							$contenttype = "text/html"
							$content = "Unknown request: $($context.Request.Url)"
						}
					}

					if (!$content) {
						$statuscode = 449
					}

					# send the response
					$response = $context.Response
					$response.StatusCode = $statuscode
					if ($statuscode -ne 449) {
						$response.Headers.Add("Content-Type", $contenttype)
						$responseBuffer = [System.Text.Encoding]::UTF8.GetBytes($content)
						$response.ContentLength64 = $responseBuffer.Length
						$response.OutputStream.Write($responseBuffer, 0, $responseBuffer.Length)
						$response.OutputStream.Close()
					}
					$response.Close()
				}
				catch [System.Management.Automation.MethodInvocationException] { }
				catch {
					"$([datetime]::Now): $_" | Out-File "api.errors.txt" -Append -Force
				}
			}
			$listner.Stop()
		}
		catch {
			"$([datetime]::Now): $_" | Out-File "api.errors.txt" -Append -Force
		}
		finally {
			$listner.Stop()
			$listner.Close()
			$listner.Dispose()
		}
	}) | Out-Null
	$global:ApiHandle = $ApiPowerShell.BeginInvoke()
}

function Stop-ApiServer {
	$global:API.Running = $false
	$global:ApiListner.Stop()
	$global:ApiPowerShell.EndInvoke($ApiHandle)
	$global:ApiRunSpace.Close()
	$global:ApiPowerShell.Dispose()	
}