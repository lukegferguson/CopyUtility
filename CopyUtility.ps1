function Copy-Utility {
    Param(
        # CSV file of servers
        [Parameter(Mandatory)]
        [string[]]$ServerCSV,
        
        #Item to be copied
        [Parameter(Mandatory)]
        [string]$Source,
        
        #Destination of item relative to server C:\
        [Parameter(Mandatory)]
        [string]$Destination,

        #Path to local logfile
        [Parameter(Mandatory)]
        [string]$LogPath
    )
    
    <#
        .SYNOPSIS
        Function to read CSV of server hostnames, test network and UNC connection to each server, then copy a file to the servers. 
        CopyUtility logs each action and will stop if log writing fails.

        .PARAMETER ServerCSV
        Path to CSV file of server names

        .PARAMETER Source
        Source path to item to be copied

        .PARAMETER Destination
        Destionation path where item will be copied to

        .PARAMETER LogPath
        Path to logfile on local machine
    #>
    
    

    function Write-Log {
        param (
            #InputObject is what is to be written to log/host
            [Parameter(
                Mandatory = $true,
                Position = 0,
                ValueFromPipelineByPropertyName = $true)]
            $InputObject,
            
            #LogPath must include filename
            $LogPath = $Logpath,
            
            #adding -WriteHost switch will show user the log message
            [switch]$WriteHost,
            
            #changes the color of text displayed to user
            $Foregroundcolor = "white",
            
            #Default action is to stop and display message on log write fail
            #Setting erroraction to "SilentlyContinue" will keep script running even if writing logs fails
            $ErrAct = "Stop"
            )
    
        try {
            if (Test-Path (Split-Path $LogPath)){
                Out-File -FilePath $LogPath -Append -InputObject "$(Get-date) $InputObject" -ErrorAction $ErrAct
    
            } else {
                New-Item -Path (Split-Path $LogPath) -ItemType Directory -ErrorAction $ErrAct | Out-Null
                Out-File -FilePath $LogPath -Append -InputObject "$(Get-date) Created log file: $logpath" -ErrorAction $ErrAct
                Out-File -FilePath $LogPath -Append -InputObject "$(Get-date) $InputObject" -ErrorAction $ErrAct
             }
        } catch {
            Write-Host "UNABLE TO WRITE LOG FILE" -ForegroundColor red -BackgroundColor White
            Write-host "Attempted to write: $InputObject"
            Write-host "System error: $_" -ForegroundColor red
            do {
                $EXIT = read-host -Prompt "EXIT to quit"
            } until ($exit -eq "exit")
            exit
        }
    
        if ($WriteHost){
            Write-Host "$InputObject" -ForegroundColor "$Foregroundcolor"
        }
    }
    
    #Wait for user input before exiting the script
    function Read-UserExit {
        do {
            $exit = Read-Host "EXIT to quit"
        } Until ($exit -eq "EXIT")
        exit
    }

#Internal variables
$FunVer = "0.02"


Write-log -WriteHost "############## Initialize Script Logging ##############" 
Write-log -WriteHost "############## OSIS Copy Utility Version $FunVer ##############"

#Test access to source file to copy, exit if it fails
if (Test-Path $Source){
    Write-Log -WriteHost "Verified access to file to copy: $Source"
 } else {
    Write-Log -WriteHost "Unable to access file to copy: $Source" -Foregroundcolor Red
    Read-UserExit
 }


 #Test access to list of servers, exit if it fails. Convert list of servers to object variable.
    try {
        $ServerObject = Get-Content $ServerCSV -ErrorAction Stop
        Write-Log -WriteHost "Successfully accessed list of servers $ServerCSV, there are $($ServerObject.count) records"
    } catch {
        Write-Log -WriteHost "Unable to access $ServerCSV" -Foregroundcolor Red
        Write-Log -WriteHost "System Error: $_"
        Read-UserExit
    }

 #Ping each server, then attempt to copy file
 #Somtimes servers fail ping, but UNC connects
    Foreach ($Server in $ServerObject) {
        
        Write-Log "Testing connection and attempting copy to $Server"
        if (test-netconnection $server){
            Write-Log -WriteHost "$Server ping SUCCESS" -Foregroundcolor green
        } else {
            Write-Log -WriteHost "$server ping FAILED, will still attempt copy" -Foregroundcolor orange
        }
        
        $ServerDrive = "\\$server\C$"

        if (Test-Path "$ServerDrive"){
            if (Test-Path "$ServerDrive\$Destination"){
                try {
                    Copy-Item -Path $Source -Destination "$ServerDrive\$Destination" -Force -ErrorAction Stop | Out-Null
                    Write-Log -WriteHost "Success: file copied to $server"
                } catch {
                    Write-Log -WriteHost "$ServerDrive\$Destination exists but copy failed" -Foregroundcolor red
                    Write-Log -WriteHost "System Error: $_" -Foregroundcolor red
                }
            } else {
                try {
                    New-Item -Path "$ServerDrive\$Destination" -ItemType Directory -Force -ErrorAction stop | Out-Null
                    Write-Log -WriteHost "Created $ServerDrive\$Destination"
                    Copy-Item -Path $Source -Destination "$ServerDrive\$Destination" -Force -ErrorAction Stop | Out-Null
                    Write-Log -WriteHost "Copied $source to $ServerDrive\$Destination"
                } catch {
                    Write-Log -WriteHost "Able to connecto to $ServerDrive, but unable to create or copy to $ServerDrive\$Destination" -Foregroundcolor red
                    Write-Log -WriteHost "System Error: $_" -Foregroundcolor red
                }
            }
        } else {
            Write-log -WriteHost "Unable to access $ServerDrive" -Foregroundcolor red
        }
    }
}

$PSDefaultParameterValues = @{
    "Copy-Utility:ServerCSV"="$Env:UserProfile\Desktop\RDS-UTL_SERVERS.csv";
    "Copy-Utility:Destination"="OSIS\SCRIPTS";
    "Copy-Utility:LogPath"="C:\OSIS\LOGS\CopyUtility.txt"
}

Copy-Utility -Source "C:\OSIS\SCRIPTS\Test.ps1"

# -ServerCSV "$Env:UserProfile\Desktop\RDS-UTL_SERVERS.csv"  -Destination "OSIS\SCRIPTS" -LogPath "C:\OSIS\LOGS\CopyUtility.txt"




