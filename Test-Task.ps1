$logFile = "$env:TEMP\task-test.log"
"Task ran successfully at $(Get-Date)" | Out-File -FilePath $logFile -Force
Start-Sleep -Seconds 5
