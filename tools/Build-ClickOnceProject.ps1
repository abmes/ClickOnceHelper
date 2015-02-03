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

    Remove-Item "$projectDir\bin\Release" -Force -Recurse
    msbuild $projectFile.FullName /verbosity:minimal /target:publish

    git commit -q -m "=============== BUILD $newAppVersion ===============" $projectFile.FullName $assemblyInfoFile.FullName
    
    echo ""
    echo "Build done."
    echo ""
    echo ""
}