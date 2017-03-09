<#
	.SYNOPSIS
		Script Name: Send Security logs out 

	.DESCRIPTION
		Sends the Windows Log "Security" to a UNC destination

	.PARAMETER  
		Server list: CSV of just server names
		Destination path: where to send the log files to (UNC Path)
		
	.NOTES
		Revision History
		Version		Author			Description		Date
		1.0			Nico Aguilera	Initial Script	3/9/2017
#>

#Region Set Parameters 
	param(
		[String] $ServerListCSV,
		[String] $DestinationUNCPath
		)
#EndRegion

		
		
#Region ScriptWork
	$CSV = get-content $ServerListCSV
	$daysAgo = (Get-Date) - (New-TimeSpan -day 7) # 7 days

	foreach ($Machine in $CSV) {
		[String]$Destination = "$DestinationUNCPath\$machine"+"_SecurityLog.csv"
        Write-Host "Exporting Security log for $Machine into $Destination"
        Get-WinEvent -computerName $machine -FilterHashtable @{logname='Security';StartTime=$daysago;ID=4624,4625,4634,4647,4648,4778,4779,4800,4801} | export-csv $Destination -force
	}#end for
