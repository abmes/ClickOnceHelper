$version = (([xml] (Get-Content "..\packages.config")).packages.package | Where-Object { $_.id -eq "Abmes.ClickOnceHelper" }).version

. "..\..\packages\Abmes.ClickOnceHelper.$version\tools\Deploy-ClickOnceProject.ps1"

Deploy-ClickOnceProject (Get-Item .\Deploy.config)

pause