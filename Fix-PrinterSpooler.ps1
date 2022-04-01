### Unblock files
Get-ChildItem -Path $PSScriptRoot -Recurse | ForEach-Object{
    Unblock-File -Path $($_.FullName)
}

### Stop Print Spooler Service
Stop-Service -DisplayName 'Print Spooler' -Force

### Remove Monitor Apps from HKLM
## Default Printers to keep
[array]$defaultPrinterMonsArr = @("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Monitors\Appmon","HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Monitors\Local Port","HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Monitors\Microsoft Shared Fax Monitor","HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port","HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Monitors\USB Monitor","HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Monitors\WSD Port")


## compare printers against defaults and filter out uniques.
$nonDefault = (Compare-Object (Get-ChildItem -Path "hklm:\SYSTEM\CurrentControlSet\Control\Print\Monitors").Name $defaultPrinterMonsArr | Where-Object -FilterScript {$_.SideIndicator -eq '<='}).InputObject
		
## Remove from Registry
if($null -ne $nonDefault){
    $nonDefault | forEach-Object{
        Remove-Item -Path "$($_.Replace("HKEY_LOCAL_MACHINE","HKLM:"))" -Recurse -Force
    }
}


### Remove files and folders in System32\Spool
Get-ChildItem -Path "$env:windir\System32\Spool\Drivers" -Recurse | ForEach-Object{
    Remove-Item -Path $($_.FullName) -Force -Recurse
}
Get-ChildItem -Path "$env:windir\System32\Spool\Printers" -Recurse | ForEach-Object{
    Remove-Item -Path $($_.FullName) -Force -Recurse
}

### Remove Printers from Print Manager
Start-Service -DisplayName 'Print Spooler'

[array]$defaultPrinters = @("OneNote (Desktop)", "Microsoft XPS Document Writer", "Microsoft Print to PDF")
$nonDefaultPrinters = (Compare-Object (Get-Printer).Name $defaultPrinters | Where-Object -FilterScript {$_.SideIndicator -eq '<='}).InputObject
if($null -ne $nonDefaultPrinters){
    $NonDefaultPrinters | ForEach-Object{
        Remove-Printer -Name $_ -Confirm:$false
    }
}


### Remove Printer Drivers
Get-PrinterDriver | Where-Object{$_.Name -notmatch "microsoft"} | ForEach-Object{
    Remove-PrinterDriver -Name $_.Name -RemoveFromDriverStore -Confirm:$false
}

## Remove Printer Port
Get-PrinterPort | Where-Object{$_.Name -match "IP_*"} | ForEach-Object {
    Remove-PrinterPort -Name $_.Name -Confirm:$false
}

### Restart the Spooler
Start-Service -Displayname "Print Spooler"