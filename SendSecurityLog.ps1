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
		1.0			Nico Aguilera	Initial Script	3/8/2017
#>

#Region Set Parameters 
	param(
		[String] $ServerListCSV,
		[String] $DestinationUNCPath
		)
#EndRegion

#region Set Script behavior.
	#Export-ModuleMember
	Set-StrictMode -Version 2.0
#endregion

#Region Functions
	Function OutputValidationLine {
	param(
		[System.String] $Label,
		[System.String] $Result,
		[System.String] $Color,
		[system.Int16]  $ScreenWidth = (get-host).ui.rawui.windowsize.width - 10,
		[Switch] $Tab,
		[Switch] $Time
	)		

	try {
		$TimeStr = "[ " + ((Get-date -DisplayHint Time -UFormat %T ).toString()) + " ] "
		$ScreenDif = $ScreenWidth - ($Label.Length + $Result.Length + 2)
		$TabWidth = $TimeStr.Length
		IF ($Time -eq $true) {
			$ScreenDif = $ScreenDif - $TimeStr.Length
			Write-Host $TimeStr -NoNewline}
		IF ($Tab -eq $true) {
			$TabStr = "     "
			$ScreenDif = $ScreenDif - $TabSTR.Length		
			Write-Host $TabSTr -NoNewline
		}
			
		$Spacer =  write-output ("." * $ScreenDif)
		$New = $Label + " " + $Spacer + " "
		
		Write-Host $New -NoNewline
		IF (($Color -eq $null) -or ($color -eq "")) 
			{Write-Host $Result}
		Elseif (($Color -ne $null) -or ($color -ne ""))
			{Write-Host $Result -ForegroundColor  $Color}
	}
	catch {
		throw
	}
}
#endregion

#Region Script
#Clear Errors and screen
Clear-Host
$Error.Clear()

#Region Declare Constants
	#[System.String[]]$RequiredWindowsComponents =@("Web-FTP-Server","Web-Mgmt-Service")
	[system.Int16] $ScreenWidth = (Get-host).ui.rawui.windowsize.width - 5
#EndRegion

#Region Declare Variables
	# Template Variables
	[System.Int32] $WarningCount = 0
	[System.int32] $ErrorCount = 0
	[System.String] $ScriptName = "SendSecurityLogs"
	[System.String] $CompanyLine = "(c) Bally Technologies Inc."
	[System.String] $ScriptLogName = "SendSecurityLogs"
	[System.String] $ScriptTitle = "Script Name: " + $ScriptName
	[System.DateTime] $ScriptStartDateTime = Get-date
	
	# Script Variables
	[System.String] $LogedinUser = [Environment]::UserName
	[System.String] $ComputerName = Get-WmiObject win32_computersystem | Select-Object -Property dnshostname -ExpandProperty dnshostname	

#EndRegion

# Start Logging
[system.string] $loggingFileName = '.\' + $ScriptLogName + '-' + ($ScriptStartDateTime).tostring("yyyyMMdd")  + '.log' 

IF (($host.name -eq "ConsoleHost") -eq $True) {Start-Transcript -Path $loggingFileName -Append | out-null}

#Region Create Script header
	Write-Host ""
	Write-output ("-" * $ScreenWidth )
	$Spacer = Write-Output (" " * ($ScreenWidth-$CompanyLine.Length - 5))
	Write-Host "|" $CompanyLine $Spacer "|"
	$Spacer = Write-Output (" " * ($ScreenWidth-$ScriptTitle.Length - 5))
	Write-Host "|" $ScriptTitle $Spacer "|"
	Write-output ("-" * $ScreenWidth)
	Write-Host ""
#EndRegion

#Region Script
Try {
		# Logging Start of Script
		Write-Host "["(Get-Date -DisplayHint Time -UFormat %T)"] Script Started"

		# Record Executing User & Computer Name
		OutputValidationLine  -Label "Computer where script executed: " -Result $ComputerName -Tab
		OutputValidationLine  -Label "User executing script: " -Result $LogedinUser -tab

		# Check for Administrator Access
		If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
		{
			OutputValidationLine -color Red -Label "Script running as administrator: "  -Tab -Result "Failed"
		}
		ElseIf (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
		{
			OutputValidationLine -color Green -Label "Script running as administrator: " -Tab -Result "Succcess"
		}
		Write-Host
		
		#Region ScriptWork
			$CSV = import-csv $ServerListCSV
			
			foreach ($Machine in $CSV) {
				OutputValidationLine -Label "     Connecting to Server: " -Tab -Result $Machine.HostName
				try {
					$Session = New-PSSession -ErrorAction Continue -ComputerName $Machine.Hostname
									
					if ($Session -ne $null) {
					
						Write-Host "Exporting $Machine"
						wevtutil export-log Security "$DestinationUNCPath\($Machine)_securityLog.evtx" /remote:$Machine /overwrite:true
						
					}
					Remove-PSSession -Session $Session
				} catch {
					throw
				}
			}			
		#EndRegion
	}
Catch {}
Finally {
		Write-Host ""
		Write-Host "["(Get-Date -DisplayHint Time -UFormat %T)"] End of script"
		Write-Host ""

		IF (($host.name -eq "ConsoleHost") -eq $True) {Stop-Transcript -ErrorAction SilentlyContinue | out-null}
	}

#EndRegion

#EndRegion 

