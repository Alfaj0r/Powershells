# inspiration : https://communities.vmware.com/thread/500805

# Connect to vCenter
Connect-VIServer "vCenterServer"

#grab all templates
$Templates = get-template in TemplatesFolder 

#iterate through all templates
foreach Template in $Templates{
    # Convert template to VM
    Set-Template -Template Template -ToVM -Confirm:$false -RunAsync
    Start-sleep -s 15
    
    #Start VM - I've seen some converted templates that prompt with the VMQuestion, so adding the command to answer with the default option was my response to it.
    Start-VM -VM Template | Get-VMQuestion | Set-VMQuestion -DefaultOption -Confirm:$false
    Start-sleep -s 45
    
    #Create variables for Guest OS credentials - This is needed for the Invoke-VMScript cmdlet to be able to execute actions inside the Guest.
    #If you don't want to enter the Guest OS local administrator password as clear text in the script, follow the steps on following link to create a file and store it as an encrypted string: Using PowerShell credentials without being prompted for a password - Stack Overflow
    
    $Username = "administrator"
    $OSPwd = cat C:\Scripts\OSPwd.txt | convertto-securestring
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $OSPwd
    
    #The following is the cmdlet that will invoke the Get-WUInstall inside the GuestVM to install all available Windows updates; optionally results can be exported to a log file to see the patches installed and related results.
    Invoke-VMScript -ScriptType PowerShell -ScriptText "Get-WUInstall –WindowsUpdate –AcceptAll –AutoReboot" -VM Template -GuestCredential $Cred | Out-file -Filepath C:\WUResults.log -Append
    
    Start-sleep -s 45
    
    #Optionally restart VMGuest one more time in case Windows Update requires it and for whatever reason the –AutoReboot switch didn’t complete it.
    Restart-VMGuest -VM Template -Confirm:$false
    
    #On a separate scheduled script or after a desired wait period, Shutdown the server and convert it back to Template.
    Shutdown-VMGuest –VM Template -Confirm:$false –RunAsync
    Start-sleep -s 120
    Set-VM –VM Template -ToTemplate -Confirm:$false
}
 
