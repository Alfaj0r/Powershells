# Grab a folder of VMware templates, convert to VM, assign to a network segment, trigger Windows updates, and then convert back to templates
# by Nico Aguilera - started on 11/2/2017

# for now, all variables are hard coded
## TO DO: parametrize vCenter IP, folder name, VM network name, credentials for target VMs(username, password), source for PSWindowsUpdate module
# script to-do/wishlist:
# - parametrize inputs: vCenter IP, vCenter credentials, vCenter folder of VMs and Templates, VM/OS credentials

#connect to vCenter
Connect-VIserver 10.0.0.100

#convert templates in a folder to VMs
$TargetTemplates = Get-folder "VMFolder" |  get-template
foreach ($target in $TargetTemplates){Set-Template $target -ToVM -RunAsync}
Write-Output "Grabbing templates and converting to VMs. They are: " $TargetTemplates

# do work on all VMs 
$TargetVMs = Get-folder "VMFolder" |  get-VM
Write-Output "Working now on all VMs..."
foreach ($VM in $TargetVMs){
    Write-Output "Now working on VM $VM..."
    #set network 
    $VM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName 'VMnetwork' -confirm:$false
    
    #power on VM, and wait a minute so it boots up and VMware tools come online
    Start-VM $VM
    Write-Output "Powered on $VM, now waiting a minute for it to finish booting up"
    Start-sleep 60
    
    #configure NICs to have a DHCP IP address - just in case they had a static configured before
    #taken from https://www.pdq.com/blog/using-powershell-to-set-static-and-dhcp-ip-addresses-part-1/, and put into $ScriptDHCP as a one liner so that it can be invoked
    $ScriptDHCP = '$IPType = "IPv4"; $adapter = Get-NetAdapter ; $interface = $adapter | Get-NetIPInterface -AddressFamily $IPType; If ($interface.Dhcp -eq "Disabled") { If (($interface | Get-NetIPConfiguration).Ipv4DefaultGateway) { $interface | Remove-NetRoute -Confirm:$false } $interface | Set-NetIPInterface -DHCP Enabled; $interface | Set-DnsClientServerAddress -ResetServerAddresses}'
    invoke-vmscript -vm $VM -ScriptText $ScriptDHCP -guestuser userName -guestpassword PlainTextPassword!!!
    
    #install powershell module to manage Windows updates: https://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc/
        #first, copy the files for the PSWindowsUpdate module package
    Copy-VMGuestFile -Source \\fileServer\Scripts\PowerShell\PSWindowsUpdate\* -Destination c:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate\ -localToGuest -Force -VM $VM -guestuser userName -guestpassword PlainTextPassword!!!
    Write-Output "Copied PSWindowsUpdate to $VM"
    
    #next, activate the Powershell module so it can be used
    invoke-vmscript -vm $VM -ScriptText "Import-Module PSWindowsUpdate" -guestuser userName -guestpassword PlainTextPassword!!!
      
    #run Windows updates by calling the PSmodule "Get-WUInstall" command. It writes a log to C:\WinUpdateResults.log! 
    # this step can take a long time, depending on how many updates the target is needing
    Invoke-VMScript -ScriptType PowerShell -ScriptText "Get-WUInstall -WindowsUpdate -AcceptAll -AutoReboot" -VM $VM -guestuser userName -guestpassword PlainTextPassword!!! | Out-file -Filepath C:\WinUpdateResults.log -Append          
    Write-Output "Invoked PSWindowsUpdate to run on $VM. You can check status on C:\WinUpdateResults.log on the computer you've executed this script (not the target VMs!)"
}

#pause and shutdown VMs. Not sure how to make the whole script wait several hours.

Write-Output "Now the tricky part... all updates have been triggered, and they're running. Probably need to sit here for a few hours."
Pause
## TO DO 
write-output "This is actually pending. Shut down the VMs yourself, and convert to templates :)"

# foreach ($VM in $TargetVMs){
#    Shutdown-VMGuest $VM -Confirm:$false -RunAsync
#}

#convert VMs back to templates 
#foreach ($VM in $TargetVMs){Set-VM $VM -ToTemplate -confirm:$false}
