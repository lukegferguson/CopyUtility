$Source = "\\IS-FS-01\SDII\ePCS\2024\eRxCertificateManagerVIPOnly_Installer_1.3.0"
$computername = "CORN-RDS-UTL-01"
$destination = "\\$computername\C$\OSIS\PACAKGES"


try {if (Test-Path $destination) {
    Copy-Item -Recurse -Path $Source  -Destination $destination -ErrorAction stop
} else {
    New-Item -ItemType Directory -Path $destination -ErrorAction stop
    Copy-Item -Recurse -Path $Source  -Destination $destination -ErrorAction stop
}
} catch {
    Write-host $_
    do {
       $exit = read-host "exit?"
    } until ($exit -eq "yes")
}

Invoke-Command -ComputerName $computername {
    msiexec.exe /i "C:\OSIS\PACAKGES\eRxCertificateManagerVIPOnly_Installer_1.3.0\eRxCertificateManagerVIPOnly_Installer_1.3.0.msi" /qn
}



