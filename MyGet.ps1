if (Test-Path -Path bin)
{
    Remove-Item bin -Recurse -Force
}

mkdir bin

Copy-Item .\Abmes.ClickOnceHelper.nuspec bin
Copy-Item .\tools .\bin -Recurse
Copy-Item .\content .\bin -Recurse

$packageVersion = $env:PackageVersion

cd bin
NuGet pack Abmes.ClickOnceHelper.nuspec -Version $packageVersion
cd..

if (-not (Test-Path "build"))
{
    mkdir build
}

Copy-Item .\bin\*.nupkg .\build

Remove-Item bin -Recurse -Force
