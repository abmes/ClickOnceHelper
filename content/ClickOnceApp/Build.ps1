$version = (([xml] (Get-Content "..\packages.config")).packages.package | Where-Object { $_.id -eq "Abmes.ClickOnceHelper" }).version

. "..\..\packages\Abmes.ClickOnceHelper.$version\tools\Build-ClickOnceProject.ps1"

Build-ClickOnceProject (Get-Item ..\*.csproj)

pause