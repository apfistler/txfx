#Set-ExecutionPolicy Bypass -Scope Process

function Configure-Environment {
    $ProjectDir = Join-Path $env:USERPROFILE "TxFx"
    $DownloadDir = Join-Path $ProjectDir "Downloads"

    if ([Environment]::Is64BitOperatingSystem) {
        $Arch = "64-bit"
    } else {
        $Arch = "32-bit"
    }

    Write-DashLine
    Write-Host "Environment Configuration"
    Write-Host
    Write-Environment-Config $ProjectDir $DownloadDir $Arch
    Write-Host

    Create-DirectoryIfNotExists $ProjectDir "Project Directory Status"
    Create-DirectoryIfNotExists $DownloadDir "Download Directory Status"

    Write-DashLine
    Write-Host

    return $ProjectDir, $DownloadDir, $Arch
}

function Create-DirectoryIfNotExists {
    param (
        [string]$Path,
        [string]$Name,
        [bool]$Echo = $true
    )

    $DirectoryCreated = $false

    if ($Echo) {
        Write-Label $Name
    }

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
        $DirectoryCreated = $true
    }

    if ($Echo) {
        Write-Label-Result $DirectoryCreated "CREATED" "EXISTS"
    }
}


function Configure-Package {
    param (
        [string]$PackageName,
        [string]$PackageVersion,
        [string]$Arch,
        [string]$ProjectDir,
        [string]$DownloadDir
    )

    Write-DashLine
    Write-Host "${PackageName} Configuration"
    Write-Host

    $PackageUrl, $PackageInstaller = Get-PackageUrl $PackageName $PackageVersion $Arch
    $PackageTarget = "${DownloadDir}\${PackageInstaller}"
    $PackageInstallDir = "${ProjectDir}\${PackageName}"

    if ( ($PackageName -eq "pscp") -or ( $PackageName -eq "puttygen" ) -or ( $PackageName -eq "psftp") ) {
      $PackageInstallDir = "${ProjectDir}\putty"
    }

    Write-Package-Config $PackageName $PackageVersion $Arch $PackageUrl $PackageInstaller $PackageTarget
    Download-Package $PackageName $PackageUrl $PackageTarget
    Install-Package $PackageName $PackageTarget $PackageInstallDir
    Export-Path $PackageName $PackageInstallDir
   

    Write-DashLine
    Write-Host
}

function Get-PackageUrl {
    param (
        [string]$PackageName,
        [string]$PackageVersion,
        [string]$Arch
    )

    $PackageUrlBase  = $null
    $PackageInstaller   = $null
    $PackageUrl           = $null

    if ($PackageName -eq 'git') {
        $GitMajorVersion = $PackageVersion.Substring(0, $PackageVersion.Length - 2)
        $GitMinorVersion = $PackageVersion.Substring($PackageVersion.Length - 2)

        $PackageUrlBase = "https://github.com/git-for-windows/git/releases/download/v${GitMajorVersion}.windows${GitMinorVersion}"
        $PackageInstaller = "Git-${PackageVersion}-${Arch}.exe"
        $PackageUrl = "${PackageUrlBase}/${PackageInstaller}"
    } elseif ($PackageName -eq 'python') {
        $archStr = $null

        if ($Arch -eq "64-bit") {
            $archStr = "-amd64"
        }

        $PackageUrlBase = "https://www.python.org/ftp/python/${PackageVersion}"
        $PackageInstaller = "python-${PackageVersion}${archStr}.exe"
        $PackageUrl = "${PackageUrlBase}/${PackageInstaller}"
    } elseif ( ($PackageName -eq "putty") -or ($PackageName -eq "pscp") -or ($PackageName -eq "puttygen") -or ($PackageName -eq "psftp") ) {

        if ($Arch -eq "64-bit") {
            $archStr = "w64"
        } else {
            $archStr = "w32"
        }

        $PackageUrlBase = "https://the.earth.li/~sgtatham/putty/latest/${archStr}"
        $PackageInstaller  = "${PackageName}.exe"
        $PackageUrl          = "${PackageUrlBase}/${PackageInstaller}"
    } elseif ($PackageName -eq "paint.net") {

        if ($Arch -eq "64-bit") {
            $archStr = "x64"
        }

        $PackageUrlBase = "https://github.com/paintdotnet/release/releases/download/v${PackageVersion}"
        $PackageInstaller  = "${PackageName}.${PackageVersion}.portable.${archStr}.zip"
        $PackageUrl          = "${PackageUrlBase}/${PackageInstaller}"
    }

    return $PackageUrl, $PackageInstaller
}

function Download-Package {
    param (
        [string]$PackageName,
        [string]$PackageUrl,
        [string]$PackageTarget
    )

    Write-Label "${PackageName} Installer Status"
    $exists = Test-FileExistsNonZero $PackageTarget

    Write-Label-Result $exists "EXISTS" "DOES NOT EXIST"

    if (-not $exists) {
        Write-Label "Downloading ${PackageName}"
        $Success = $false

        $response = Invoke-WebRequest -Uri $PackageUrl -OutFile $PackageTarget
        $Success = Test-FileExistsNonZero $PackageTarget

        Write-Label-Result $Success "SUCCESSFUL" "FAILED"
    }
}

function Test-Package-Installed {
    param (
        [string]$PackageName,
        [string]$PackageInstallDir
    )

    $PackageExecutable = $null

    if ($PackageName -eq "git") {
        $PackageExecutable = "${PackageInstallDir}\bin\git.exe"
    } elseif ($PackageName -eq "python") {
        $PackageExecutable = "${PackageInstallDir}\python.exe"
    } elseif ($PackageName -eq "paint.net") {
        $PackageExecutable = "${PackageInstallDir}\paintdotnet.exe"
    } elseif ( ($PackageName -eq "putty" ) -or ($PackageName -eq "pscp") -or ($PackageName -eq "puttygen") -or ($PackageName -eq "psftp") ) {
       $PackageExecutable = "${PackageInstallDir}\${PackageName}.exe" 
    }

    return Test-FileExistsNonZero $PackageExecutable
}

function Install-Package {
    param (
        [string]$PackageName,
        [string]$PackageInstaller,
        [string]$PackageInstallDir
    )

    Write-Label "Recheck ${PackageName} Installer Status"
    $exists = Test-FileExistsNonZero $PackageInstaller
    Write-Label-Result $exists "EXISTS" "DOES NOT EXIST"

    if ($exists) {
        Write-Label "Checking ${PackageName} Status"
        $installed = Test-Package-Installed $PackageName $PackageInstallDir
        Write-Label-Result $installed "INSTALLED" "NOT INSTALLED"

        if ($installed) {
            return
        }

        Write-Label "Installing ${PackageName}"

        $success = $false
        $args = $null

        if ($PackageName -eq 'git') {
            $args = "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS",
                         "/COMPONENTS=icons,ext\reg\shellhere,assoc,assoc_sh", "/DIR=`"${PackageInstallDir}`""
            $processInfo = Start-Process -FilePath $PackageInstaller -ArgumentList ($args -join " ") -Wait
        } elseif ($PackageName -eq 'python') {
            $args =  "/quiet",  "PrependPath=1",  "TargetDir=`"${PackageInstallDir}`"", "Include_launcher=0"
            $processInfo = Start-Process -FilePath $PackageInstaller -ArgumentList ($args -join " ") -Wait
 
       } elseif ($PackageName -eq 'paint.net') {
            Expand-Archive -Path ${PackageInstaller} -DestinationPath ${PackageInstallDir}
       } elseif ( ($PackageName -eq "Putty") -or ($PackageName -eq "pscp") -or ($PackageName -eq "puttygen") -or ($PackageName -eq "psftp") ){         
           Create-DirectoryIfNotExists -Path $PackageInstallDir -Name "Putty Install Dir" -Echo $false
           Move-Item -Path $PackageInstaller -Destination $PackageInstallDir
       }


        # For some reason processInfo is empty on some machines and I can't reliably use an exit code of 0 for success.
        if (Test-Package-Installed $PackageName $PackageInstallDir) {
            $success = $true
        } else {
            $success = $false
        }

        Write-Label-Result $success "SUCCESSFUL" "FAILED"

        if (-not $success) {
            Exit-Error "Installation of ${PackageName} from ${PackageInstaller} failed to install to ${PackageInstallDir}"
        }
    } else {
        Exit-Error "${PackageName} Installer $PackageInstaller not found."
    }
}

function Export-Path {
    param (
        [string]$PackageName,
        [string]$PackageInstallDir
    )

    $currentPath = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
    $newPath = $null

    if ($PackageName -eq "git") {
        $newPath = "${PackageInstallDir}\bin"
    } elseif ($PackageName -eq "python") {
        $newPath = "${PackageInstallDir};${PackageInstallDir}\scripts"
    } elseif ($PackageName -eq "paint.net") {
        $newPath = "${PackageInstallDir}"
    } elseif ( ($PackageName -eq "putty" ) -or ($PackageName -eq "pscp") -or ($PackageName -eq "puttygen") -or ($PackageName -eq "psftp") ){
        $newPath = "${PackageInstallDir}"
    }

    $pathArray = $currentPath -split ';' | Select-Object -Unique
    $pathArray += $newPath
    $newPath = $pathArray -join ';'

    [Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)
    $env:PATH = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)

    Write-Label "Exporting PATH"
    Write-Label-Result 1 "SUCCESSFUL" "FAILED"
}

function Test-FileExistsNonZero {
    param (
        [string]$FileName
    )

    if (Test-Path $FileName -PathType Leaf) {
        $fileInfo = Get-Item $FileName
        $fileSize = $fileInfo.Length

        return $fileSize -gt 0
    }

    return $false
}

function Write-Environment-Config {
    param(
         [string]$ProjectDir,
         [string]$DownloadDir,
         [string]$Arch
    )

    Write-Label "Architecture" $Arch
    Write-Label "Project Directory" $ProjectDir
    Write-Label "Download Directory" $DownloadDir
}

function Write-Package-Config {
    param(
        [string]$PackageName,
        [string]$PackageVersion,
        [string]$Arch,
        [string]$PackageUrl,
        [string]$PackageInstaller,
        [string]$PackageTarget
    )

    Write-Label "${PackageName} Version" $PackageVersion
    Write-Label "Architecture" $Arch
    Write-Label "${PackageName} Executable" $PackageInstaller
    Write-Label "${PackageName} URL" $PackageUrl
    Write-Label "${PackageName} Target" $PackageTarget
}

function Write-Label {
    param (
        [string]$Label,
        [string]$Text = $null
    )

    $FormattedText = "{0,-40}" -f $Label
    Write-Host -NoNewLine ($FormattedText + " : ")

    if ($Text) {
        Write-Host $Text
    }
}

function Write-Label-Result {
    param (
        [bool]$Success,
        [string]$TrueText,
        [string]$FalseText
    )

    if ($Success) {
        $Text = $TrueText
    } else {
        $Text = $FalseText
    }

    Write-Host $Text
}

function Write-DashLine {
    param (
        [int]$Count = 140
    )

    Write-Host ('-' * $Count)
}
function Exit-Error {
    param (
        [string]$Message
    )

    Write-Host "ERROR: $Message"
    exit 1
}

function Main {
    $packages = @{
        'git'       = @{ 'version' = '2.41.0.3' }
        'python'    = @{ 'version' = '3.11.1' }
        'paint.net' = @{ 'version' = '5.0.12' }
        'putty'     = @{ 'version' = 'latest' }
        'pscp'      = @{ 'version' = 'latest' }
        'puttygen'  = @{ 'version' = 'latest' }
        'psftp'     = @{ 'version' = 'latest' }
    }

    Clear-Host
    Write-Host "Configuring TxFx Development Environment..."
    Write-Host
    $ProjectDir, $DownloadDir, $Arch = Configure-Environment

    foreach ($packageEntry in $packages.GetEnumerator()) {
        $packageName = $packageEntry.Key
        $packageVersion = $packageEntry.Value['version']
   
        Configure-Package $packageName  $packageVersion $Arch $ProjectDir $DownloadDir
    }
}

Main
