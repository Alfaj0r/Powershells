### Standard SQL server review

## Step 0: Script start
write-host "**********************************************************"
$now = Get-Date  # log the current date/time
write-host "SQL Server Review script started on "  $now  # write it
write-host "**********************************************************"

## Step1: collect

# Server basic info
$ServerBasicInfo = Get-WmiObject -query "select * from Win32_ComputerSystem" | select Name, DNSHostName, Domain, PartOfDomain, Manufacturer, Model

# Server hardware specs: 
#CPU
$CPU_count = Get-WmiObject win32_computersystem | select-object NumberOfProcessors
$CPU_cores= Get-WmiObject win32_processor | Format-List NumberOfCores
$CPU_threads = ((Get-WmiObject Win32_Processor)| Measure-Object NumberOfCores -sum).sum 

#RAM
$totalmemory = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | Foreach {"{0:N2}" -f ([math]::round(($_.Sum / 1GB),2))}

# Windows version
# Get Operating System Info

$systemOS =Get-WmiObject -class Win32_OperatingSystem 

$OSDescription = $systemOS.Caption
$OSServicePack = $systemOS.ServicePackMajorVersion


# Hard drives

#This function returns the Allocation Unit Size (in KB, as made clear by the function's name)
 function GetDiskAllocUnitSizeKB([char[]]$drive = $null)
{
    $wql = "SELECT BlockSize FROM Win32_Volume " + `
           "WHERE FileSystem='NTFS' and DriveLetter = '" + $drive + ":'"
    $BytesPerCluster = Get-WmiObject -Query $wql -ComputerName '.' `
                        | Select-Object BlockSize
    return $BytesPerCluster.BlockSize/1024 ;
}

#Run on all local drives: GetDiskAllocUnitSizeKB
$LocalDrives = Get-WmiObject -Class Win32_Volume -Filter "DriveType=3"
foreach ($drive in $LocalDrives) {
    
    $AllocUnitSize = GetDiskAllocUnitSizeKB $drive.driveletter.substring(0,1) # only want the drive letter, not the colon
    write-host "Drive" $drive.driveletter "(" $drive.label       ") has a block size of" $AllocUnitSize "KB"
    
    write-host "Disk size:" ([Math]::round($drive.capacity /1073741824)) "GB"
    write-host "Disk free space:" ([Math]::round($drive.freespace /1073741824)) "GB"
    write-host "Disk percentage free:" ([Math]::round(($drive.freespace/$drive.capacity)*100)) "%"
  }

# Windows page file

# SQL version

# SQL Server Engine

# Memory max/min

# Max DOP

# TraceFlags

# SPN registration

# Databases installed: location, configuration

# DBMR or DMS status

# Security Policy

# Lock Pages in Memory?

# Perform volume maintenance tasks?

# Replace process level token?

# grab logs, last 7 days 

# Windows - Application

# Windows - syste

# SQL


## Step 2: Analyze?


## Step3: Output
Write-Host "************* System Info collected:  ********************"


write-host "**********************************************************"
Write-Host "***Server Info:"
$ServerBasicInfo
write-host "**********************************************************"

Write-Host "***Processor and Memory Info:"
Write-Host "CPU Count:"$CPU_count
Write-Host "CPU Cores:"$CPU_cores
Write-Host "CPU vCPU:"$CPU_vCPU
Write-Host "Total Memory:"$totalmemory"GB"

write-host "**********************************************************"
Write-Host "*** OS info:"
Write-Host "OS:"$OSDescription
Write-Host "Service Pack:"$OSServicePack

