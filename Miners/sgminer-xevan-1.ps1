<#
MindMiner  Copyright (C) 2017  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

. .\Code\Include.ps1

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Cfg = [BaseConfig]::ReadOrCreate([IO.Path]::Combine($PSScriptRoot, $Name + [BaseConfig]::Filename), @{
	Enabled = $true
	BenchmarkSeconds = 60
	Algorithms = @(
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "xevan"; ExtraArgs="-I 15 -g 2" } #fastest for all?
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "xevan"; ExtraArgs="-I 15" } #460/560
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "xevan"; ExtraArgs="-I 19" } #470/570
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "xevan"; ExtraArgs="-I 21" } #480/580
		[AlgoInfoEx]@{ Enabled = $true; Algorithm = "xevan"; ExtraArgs="-I 23" } #vega?
	)
})

if (!$Cfg.Enabled) { return }

if ([Config]::Is64Bit -eq $true) {
	$url = "https://github.com/LIMXTEC/Xevan-GPU-Miner/releases/download/1/sgminer-xevan-5.5.0-nicehash-1-windows-amd64.zip"
}
else {
	$url = "https://github.com/LIMXTEC/Xevan-GPU-Miner/releases/download/1/sgminer-xevan-5.5.0-nicehash-1-windows-i386.zip"
}

$Cfg.Algorithms | ForEach-Object {
	if ($_.Enabled) {
		$Algo = Get-Algo($_.Algorithm)
		if ($Algo) {
			# find pool by algorithm
			$Pool = Get-Pool($Algo)
			if ($Pool) {
				$pass = Get-PasswordString $Algo $Pool.Password
				[MinerInfo]@{
					Pool = $Pool.PoolName()
					PoolKey = $Pool.PoolKey()
					Name = $Name
					Algorithm = $Algo
					Type = [eMinerType]::AMD
					API = "sgminer"
					URI = $url
					Path = "$Name\sgminer.exe"
					ExtraArgs = $_.ExtraArgs
					Arguments = "-k $($_.Algorithm) -o stratum+tcp://$($Pool.Host):$($Pool.PortUnsecure) -u $($Pool.User) -p $pass --api-listen --gpu-platform $([Config]::AMDPlatformId) $($_.ExtraArgs)"
					Port = 4028
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
				}
			}
		}
	}
}