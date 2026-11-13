$newPassword = "Admin@123"
Get-LocalUser | Where-Object { $_.Enabled -eq $true } | ForEach-Object { 
    try { Set-LocalUser -Name $_.Name -Password (ConvertTo-SecureString $newPassword -AsPlainText -Force); Write-Output "Changed password for $($_.Name)" } 
    catch { Write-Output "Failed for $($_.Name): $_" } 
} | Out-File "PasswordChangeLog.txt"
