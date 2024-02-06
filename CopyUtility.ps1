#Variables
$ScriptVer = "0.01"
#ideally pop up an Explorer GUI window for user to select the file
$ServerCSV = "C:\OSIS\SCRIPTS\RDS-UTL_SERVERS.csv"
$LogPath = "C:\OSIS\LOGS\UtilityCopy.txt"
$PackageDest = "OSIS\PACKAGES"
$FiletoCopy = "\\is-fs-01\SDII\Test\Test.ps1"


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

Write-log -WriteHost "############## Initialize Script Logging ##############" 
Write-log -WriteHost "############## OSIS Utility Copy Script Version $ScriptVer ##############" 

#Test access to file to copy, exit if it fails
 if (Test-Path $FiletoCopy){
    Write-Log -WriteHost "Verified access to file to copy: $filetocopy"
 } else {
    Write-Log -WriteHost "Unable to access file to copy: $Filetocopy" -Foregroundcolor Red
    Read-UserExit
 }


try {
    $ServerObject = Get-Content $ServerCSV -ErrorAction Stop
    Write-Log -WriteHost "Successfully accessed list of servers $ServerCSV, there are $($ServerObject.count) records"
} catch {
    Write-Log -WriteHost "Unable to access $ServerCSV" -Foregroundcolor Red
    Write-Log -WriteHost "System Error: $_"
    Read-UserExit
}

 #Ping each server, then attempt to copy file
Foreach ($Server in $ServerObject) {
    Write-Log "Testing connection and attempting copy to $Server"
    Write-Log -WriteHost "Receive Ping reply from $Server : $($(Test-Netconnection $server).PingSucceeded)"
    
    $ServerC = "\\$server\C$\"

    If (Test-Path "$ServerC"){
        try { 
            Write-Log -WriteHost "Attempting to create $ServerC$PackageDest"
            New-Item -Path "$ServerC$PackageDest" -ItemType Directory -Force -ErrorAction stop | Out-Null
            Write-Log -WriteHost "Created $ServerC$PackageDest"
            Copy-Item -Path $FiletoCopy -Destination "$ServerC$packagedest" -Force -ErrorAction Stop | Out-Null
            Write-Log -WriteHost "Success: file copied to $server"
        } catch {
            Write-Log -WriteHost "Unable to create $serverC$PackagDest or copy file" -Foregroundcolor red
            Write-log -WriteHost "System Error $_"
        }
    } else {
        Write-log -WriteHost "Unable to access $ServerC"
    }
}







