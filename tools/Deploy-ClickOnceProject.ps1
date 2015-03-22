function Check-FtpCredentials($ftp, $credentials)
{
    $request = [System.Net.WebRequest]::Create($ftp)
    $request.Credentials = $credentials
    $request.Method = [System.Net.WebRequestMethods+FTP]::PrintWorkingDirectory
    $response = $request.GetResponse()
}

function Make-FtpFolder($ftpPath, $credentials)
{
    $makeDirectory = [System.Net.WebRequest]::Create($ftpPath)
    $makeDirectory.Credentials = $credentials
    $makeDirectory.Method = [System.Net.WebRequestMethods+FTP]::MakeDirectory
    $makeDirectory.GetResponse()
}

function Ensure-FtpFolderExists($ftpPath, $credentials)
{
    try
    {
        Make-FtpFolder $ftpPath $credentials
    }
    catch
    {
        # do nothing
    }
}

function Upload-File ($sourceFile, $ftpDestinationFile, $credentials)
{
    $webClient = New-Object System.Net.WebClient 
    $webClient.Credentials = $credentials
    $uri = New-Object System.Uri($ftpDestinationFile) 
    $webclient.UploadFile($uri, $sourceFile.FullName)  
}

function Upload-Directory($sourcePath, $ftp, $ftpAppDir, $path, $credentials)
{
    Ensure-FtpFolderExists ($ftp + $ftpAppDir + $path) $credentials
    
    foreach ($file in Get-ChildItem $sourcePath | where { ! $_.PSIsContainer })
    {
        Upload-File $file ($ftp + "$ftpAppDir" + "$path/" + ($file.Name)) $credentials
    }

    foreach ($subDir in Get-ChildItem $sourcePath | where { $_.PSIsContainer })
    {
        Upload-Directory "$sourcePath\$subDir" $ftp $ftpAppDir "$path/$subDir" $credentials
    }
}

function Rename-FtpFolder($ftpPath, $newName, $credentials)
{
    [System.Net.FtpWebRequest] $renameDirectory = [System.Net.FtpWebRequest]::Create($ftpPath)
    $renameDirectory.Credentials = $credentials
    $renameDirectory.Method = [System.Net.WebRequestMethods+FTP]::Rename
    $renameDirectory.RenameTo = $newName
    $renameDirectory.GetResponse()
}

function TryRename-FtpFolder($ftpPath, $newName, $credentials)
{
    try
    {
        Rename-FtpFolder $ftpPath $newName $credentials
        return $true
    }
    catch
    {
        return $false
    }
}

function DoDeploy-ClickOnceProject([string] $sourceDir, [string] $ftp, [string] $ftpAppDir, [string] $user, [string] $pass)
{
    if ([string]::IsNullOrEmpty($user) -or [string]::IsNullOrEmpty($pass))
    {
        $credentials = Get-Credential -UserName "$user" -Message "Enter ftp credential"
    }
    else
    {
        $credentials = New-Object System.Net.NetworkCredential($user, $pass)
    }

    Check-FtpCredentials $ftp $credentials

    Ensure-FtpFolderExists ($ftp + $ftpAppDir) $credentials

    if (TryRename-FtpFolder ($ftp + $ftpAppDir) "$ftpAppDir-old" $credentials)
    {
        Upload-Directory $sourceDir $ftp $ftpAppDir "" $credentials
        echo "Deployment done"
    }
    else
    {
        echo "Please delete the $ftpAppDir-old folder first!"
    }
}

function Deploy-ClickOnceProject([System.IO.FileInfo] $configFile)
{
    Get-Content $configFile.FullName | %{$config = @{}} {if ($_ -match "(.*)=(.*)") {$config[$matches[1]]=$matches[2];}}
    DoDeploy-ClickOnceProject $config["SourceDir"] $config["Ftp"] $config["FtpAppDir"] $config["User"] $config["Pass"]
}