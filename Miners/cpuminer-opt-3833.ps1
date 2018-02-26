<#
MindMiner  Copyright (C) 2017  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

. .\Code\Include.ps1

if (![Config]::Is64Bit) { exit }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Cfg = [BaseConfig]::ReadOrCreate([IO.Path]::Combine($PSScriptRoot, $Name + [BaseConfig]::Filename), @{
	Enabled = $true
	BenchmarkSeconds = 30
	Algorithms = @(
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "axiom" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "blakecoin" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "blake2s" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "c11" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "cryptonight" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "decred" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "groestl" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "hmq1725" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "hodl" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "jha" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "keccak" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "lbry" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "lyra2h" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "lyra2rev2" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "lyra2z" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "m7m" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "myr-gr" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "neoscrypt" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "nist5" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "phi1612" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "polytimos" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "quark" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "qubit" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "skein" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "skunk" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "timetravel" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "timetravel10" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "tribus" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "veltor" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "x12" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "x11evo" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "x11gost" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "x13sm3" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "x16r" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "x17" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "xevan" }
	[AlgoInfoEx]@{ Enabled = $true; Algorithm = "yescrypt" }
	#[AlgoInfoEx]@{ Enabled = $true; Algorithm = "sib"; ExtraArgs = "-i 21" }
)})

if (!$Cfg.Enabled) { return }

# choose version
$miners = [Collections.Generic.Dictionary[string, string[]]]::new()
$miners.Add("cpuminer-sse2.exe", @("SSE2"))
$miners.Add("cpuminer-aes-sse42.exe", @("AES", "SSE42"))
$miners.Add("cpuminer-aes-avx.exe", @("AES", "AVX"))
$miners.Add("cpuminer-avx2.exe", @("AES", "AVX2"))
$miners.Add("cpuminer-avx2-sha.exe", @("SHA", "AVX2"))

$bestminer = $null
$miners.GetEnumerator() | ForEach-Object {
	$has = $true
	$_.Value | ForEach-Object {
		if (![Config]::CPUFeatures.Contains($_)) {
			$has = $false
		}
	}
	if ($has) {
		$bestminer = $_.Key
	}
}

$Cfg.Algorithms | ForEach-Object {
	if ($_.Enabled) {
		$Algo = Get-Algo($_.Algorithm)
		if ($Algo) {
			# find pool by algorithm
			$Pool = Get-Pool($Algo)
			if ($Pool) {
				[MinerInfo]@{
					Pool = $Pool.PoolName()
					PoolKey = $Pool.PoolKey()
					Name = $Name
					Algorithm = $Algo
					Type = [eMinerType]::CPU
					API = "cpuminer"
					URI = "https://github.com/JayDDee/cpuminer-opt/files/1756603/cpuminer-opt-3.8.3.3-windows.zip"
					Path = "$Name\$bestminer"
					ExtraArgs = $_.ExtraArgs
					Arguments = "-a $($_.Algorithm) -o stratum+tcp://$($Pool.Host):$($Pool.PortUnsecure) -u $($Pool.User) -p $($Pool.Password) -b 4048 --cpu-priority 1 -R 5 $($_.ExtraArgs)"
					Port = 4048
					BenchmarkSeconds = if ($_.BenchmarkSeconds) { $_.BenchmarkSeconds } else { $Cfg.BenchmarkSeconds }
				}
			}
		}
	}
}