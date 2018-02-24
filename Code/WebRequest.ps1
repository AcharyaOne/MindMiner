<#
MindMiner  Copyright (C) 2017  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

$WebReqTryCount = 3

function GetUrl {
	param(
		[Parameter(Mandatory = $true)]
		[String]$url,
		[Parameter(Mandatory = $false)]
		[String]$filename
	)

	if ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls12) {
		[Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
	}
		
	$result = $null

	1..$WebReqTryCount | ForEach-Object {
		if (!$result) {
			try {
				if ($filename) {
					$req = Invoke-WebRequest $url -OutFile $filename -PassThru -TimeoutSec 15
					$result = $true
				}
				else {
					$req = Invoke-WebRequest $url -TimeoutSec 15
					$result = $req | ConvertFrom-Json
				}
			}
			catch {
				if ($req -is [IDisposable]) {
					$req.Dispose()
					$req = $null
				}
				try {
					if ($filename) {
						$req = Invoke-WebRequest $url -OutFile $filename -PassThru -TimeoutSec 15 -UseBasicParsing
						$result = $true
					}
					else {
						$req = Invoke-WebRequest $url -TimeoutSec 15 -UseBasicParsing
						$result = $req | ConvertFrom-Json
					}
				}
				catch {
					$result = $null
				}
			}
			finally {
				if ($req -is [IDisposable]) {
					$req.Dispose()
				}
			}
		}
	}

	$result
}

function Get-UrlAsJson {
	param(
		[Parameter(Mandatory = $true)]
		[String]$url
	)

	GetUrl $url
}

function Get-UrlAsFile {
	param(
		[Parameter(Mandatory = $true)]
		[String]$url,
		[Parameter(Mandatory = $true)]
		[String]$filename
	)

	GetUrl $url $filename
}