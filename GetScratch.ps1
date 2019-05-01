$scratch="ScratchConfig.ConfiguredScratchLocation"
&{foreach($esx in Get-VMHost){
  Get-AdvancedSetting -Entity $esx -Name $scratch |
  Select @{N="ESXi";E={$esx.Name}},Value
}} | ConvertTo-Html | Out-File C:\Scripts\Scratch_report.html

Invoke-Item c:\Scripts\Scratch_report.html