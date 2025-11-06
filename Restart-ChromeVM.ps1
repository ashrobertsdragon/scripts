$ErrorActionPreference = "Stop"

$startDir = $PWD

cd C:\Users\ashro\vscode\listen\terraform
terraform taint module.chrome_vm.google_compute_instance.chrome_vm
terraform apply -auto-approve
Write-Output "Waiting 5 minutes for VM to be ready..."
Start-Sleep -s 60
Write-Output "4 minutes to go..."
Start-Sleep -s 60
Write-Output "3 minutes to go..."
Start-Sleep -s 60
Write-Output "2 minutes to go..."
Start-Sleep -s 60
Write-Output "1 minute to go..."
Start-Sleep -s 60
& C:\Users\ashro\vscode\listen\terraform\reconnect.ps1

cd $startDir