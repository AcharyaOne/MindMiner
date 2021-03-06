<#
MindMiner  Copyright (C) 2018  Oleg Samsonov aka Quake4
https://github.com/Quake4/MindMiner
License GPL-3.0
#>

function Get-RateInfo {
	$result = [Collections.Generic.Dictionary[string, object]]::new()

	$conins = [Collections.ArrayList]::new()
	$conins.AddRange(@("BTC"));
	$Config.Wallet | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $conins.AddRange(@("$_")) }
	$conins | ForEach-Object {
		$wallet = "$_"
		# only BTC if show balance is off
		if (!$result.ContainsKey($wallet) -and ($wallet.Contains("BTC") -or $Config.ShowBalance -eq $true)) {
			$json = Get-UrlAsJson "https://api.coinbase.com/v2/exchange-rates?currency=$wallet"
			if ($json) {
				$values = [Collections.Generic.List[object]]::new()
				$Config.Currencies | ForEach-Object {
					if ([string]::Equals($_[0], $wallet, [StringComparison]::InvariantCultureIgnoreCase)) {
						$values.Add(@($wallet, [decimal]1))
					}
					elseif ([string]::Equals($_[0], "m$wallet", [StringComparison]::InvariantCultureIgnoreCase)) {
						$values.Add(@("m$wallet", [decimal]1000))
					}
					elseif ($json.data.rates."$($_[0])") {
						$values.Add(@($_[0], [decimal]$json.data.rates."$($_[0])"))
					}
				}
				$result.Add($wallet, $values)
			}
		}
	}
	,$result
}