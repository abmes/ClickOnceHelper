Set-Alias msbuild "C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"
Set-Alias git "C:\Program Files (x86)\Git\bin\git.exe"

function Build-ClickOnceProject([System.IO.FileInfo] $projectFile)
{
    echo "Building $($projectFile.BaseName)..."
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo ""

    [string] $projectDir = $projectFile.DirectoryName
    [int] $appRevision = 0

    $xml = [xml] (Get-Content $projectFile.FullName)
    foreach ($x in $xml.Project.PropertyGroup)
    {
        if ($x.ApplicationRevision -ne $null)
        {
            $appRevision = ([int]($x.ApplicationRevision) + 1)
            $x.ApplicationRevision = $appRevision.ToString()
        }

        if ($x.ApplicationVersion -ne $null)
        {
            $appVersion = $x.ApplicationVersion
        }
    }

    $xml.Save($projectFile.FullName)

    
    $oldAppVersion = $appVersion.Replace("%2a", ($appRevision-1).ToString())
    $newAppVersion = $appVersion.Replace("%2a", $appRevision.ToString())

    $assemblyInfoFile = Get-ChildItem -Path $projectDir -Recurse -Filter "AssemblyInfo.cs"
    
    $oldAssemblyInfo = Get-Content $assemblyInfoFile.FullName
    $newAssemblyInfo = $oldAssemblyInfo.Replace($oldAppVersion, $newAppVersion)
    Set-Content $assemblyInfoFile.FullName $newAssemblyInfo

    if (Test-Path "$projectDir\bin\Release") { Remove-Item "$projectDir\bin\Release" -Force -Recurse }
    
    $programFiles86 = (${env:ProgramFiles(x86)}, ${env:ProgramFiles} -ne $null)[0]
    $visualStudioVersion = (Get-ChildItem -Path $programFiles86 -Filter "Microsoft Visual Studio*")[-1].Name.Split(' ')[-1]
    
    msbuild $projectFile.FullName /verbosity:minimal /target:publish /p:Configuration=Release /p:VisualStudioVersion=$visualStudioVersion

    git commit -q -m "=============== BUILD $newAppVersion ===============" $projectFile.FullName $assemblyInfoFile.FullName
    
    echo ""
    echo "Build done."
    echo ""
    echo ""
}