configuration ChocolateyPackages {
    param (
        [Parameter()]
        [hashtable]$Software,

        [Parameter()]
        [hashtable[]]$Sources,

        [Parameter()]
        [hashtable[]]$Packages,

        [Parameter()]
        [hashtable[]]$Features
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName Chocolatey

    $chocoSwExecName = 'Choco_Software'

    if( $Software -ne $null ) {

        if( [String]::IsNullOrWhiteSpace($Software.OfflineInstallZip) -eq $false )
        {
            Script OfflineInstallChocolatey
            {
                TestScript = {
                    # origin: https://github.com/chocolatey-community/Chocolatey/blob/master/Chocolatey/public/Test-ChocolateyInstall.ps1

                    try {
                        Write-Verbose "Loading machine Path Environment variable into session."
                        $envPath = [Environment]::GetEnvironmentVariable('Path','Machine')
                        [Environment]::SetEnvironmentVariable($envPath,'Process')

                        $InstallDir = $Using:Software.InstallationDirectory

                        if ($InstallDir -and (Test-Path $InstallDir) ) {
                            $InstallDir = (Resolve-Path $InstallDir -ErrorAction Stop).Path
                        }

                        if ($chocoCmd = get-command choco.exe -CommandType Application -ErrorAction SilentlyContinue)
                        {
                            if (
                                !$InstallDir -or
                                $chocoCmd.Path -match [regex]::Escape($InstallDir)
                            )
                            {
                                Write-Verbose ('Chocolatey Software found in {0}' -f $chocoCmd.Path)
                                return $true
                            }
                            else
                            {
                                Write-Verbose (
                                    'Chocolatey Software not installed in {0}`n but in {1}' -f $InstallDir,$chocoCmd.Path
                                )
                                return $false
                            }
                        }
                        else {
                            Write-Verbose "Chocolatey Software not found."
                            return $false
                        }
                    }
                    catch {
                        Write-Verbose "Test for Chocolatey Software aborted with an exception.`n$_"
                        return $false
                    }
                }

                SetScript = {
                    # origin: https://github.com/chocolatey-community/Chocolatey/blob/master/Chocolatey/public/Install-ChocolateySoftware.ps1

                    if ($null -eq $env:TEMP) {
                        $env:TEMP = Join-Path $Env:SYSTEMDRIVE 'temp'
                    }

                    $tempDir = [io.path]::Combine($Env:TEMP,'chocolatey','chocInstall')
                    if (![System.IO.Directory]::Exists($tempDir)) {
                        $null = New-Item -path $tempDir -ItemType Directory
                    }

                    if( -not (Test-Path $Using:Software.OfflineInstallZip) ) {
                        throw "Offline installation package '$($Using:Software.OfflineInstallZip)' not found."
                    }

                    # copy the package with zip extension
                    $file = Resolve-Path $Using:Software.OfflineInstallZip
                    $zipFile = [io.path]::Combine($Env:TEMP,'chocolatey','chocolatey.zip')

                    Write-Verbose "Copy install package '$file' to '$zipFile'..."

                    Copy-Item -Path $file -Destination $zipFile -Force

                    # unzip the package
                    Write-Verbose "Extracting $zipFile to $tempDir..."

                    if ($PSVersionTable.PSVersion.Major -ge 5) {
                        Expand-Archive -Path "$zipFile" -DestinationPath "$tempDir" -Force
                    }
                    else {
                        try {
                            $shellApplication = new-object -com shell.application
                            $zipPackage = $shellApplication.NameSpace($zipFile)
                            $destinationFolder = $shellApplication.NameSpace($tempDir)
                            $destinationFolder.CopyHere($zipPackage.Items(),0x10)
                        }
                        catch {
                            throw "Unable to unzip package using built-in compression. Error: `n $_"
                        }
                    }

                    # Call chocolatey install
                    Write-Verbose "Installing chocolatey on this machine."
                    $TempTools = [io.path]::combine($tempDir,'tools')
                    #   To be able to mock
                    $chocInstallPS1 = Join-Path $TempTools 'chocolateyInstall.ps1'

                    $chocoInstallDir = $Using:Software.InstallationDirectory

                    if ($chocoInstallDir -ne $null -and $chocoInstallDir -ne '') {
                        Write-Verbose "Set Chocolatey installation directory to '$chocoInstallDir'"

                        [Environment]::SetEnvironmentVariable('ChocolateyInstall', $chocoInstallDir, 'Machine')
                        [Environment]::SetEnvironmentVariable('ChocolateyInstall', $chocoInstallDir, 'Process')
                    }

                    Write-Verbose "EnvVar 'ChocolateyInstall': $([Environment]::GetEnvironmentVariable('ChocolateyInstall'))"

                    & $chocInstallPS1 | Write-Verbose

                    Write-Verbose 'Ensuring chocolatey commands are on the path.'
                    $chocoPath = [Environment]::GetEnvironmentVariable('ChocolateyInstall')
                    if ($chocoPath -eq $null -or $chocoPath -eq '') {
                        $chocoPath = "$env:ALLUSERSPROFILE\Chocolatey"
                    }

                    if (!(Test-Path ($chocoPath))) {
                        $chocoPath = "$env:SYSTEMDRIVE\ProgramData\Chocolatey"
                    }

                    $chocoExePath = Join-Path $chocoPath 'bin'

                    if ($($env:Path).ToLower().Contains($($chocoExePath).ToLower()) -eq $false) {
                        $env:Path = [Environment]::GetEnvironmentVariable('Path',[System.EnvironmentVariableTarget]::Machine)
                    }

                    Write-Verbose 'Ensuring chocolatey.nupkg is in the lib folder'
                    $chocoPkgDir = Join-Path $chocoPath 'lib\chocolatey'
                    $nupkg = Join-Path $chocoPkgDir 'chocolatey.nupkg'
                    $null = [System.IO.Directory]::CreateDirectory($chocoPkgDir)
                    Copy-Item "$file" "$nupkg" -Force -ErrorAction SilentlyContinue

                    if ($ChocoVersion = & "$chocoPath\choco.exe" -v) {
                        Write-Verbose "Installed Chocolatey Version: $ChocoVersion"
                    }

                    # reboot machine to activate the new environment variables for DSC
                    $global:DSCMachineStatus = 1
                }

                GetScript = { return @{result = 'N/A'} }
           }

           $Software.Remove('OfflineInstallZip')
           $Software.DependsOn = '[Script]OfflineInstallChocolatey'
        }

        (Get-DscSplattedResource -ResourceName ChocolateySoftware -ExecutionName $chocoSwExecName -Properties $Software -NoInvoke).Invoke($Software)
    }
    Write-Verbose "Pre Features early check"
    $datetime = get-date
    Write-Verbose "KWChocolateyPackages2 Set at $datetime"
    "Time to set features in ChocolateyPackages.schema.psm1 is $datetime" >> c:\temp\SetChocolateyPackages.txt

    if( $Features -ne $null ) {
        foreach ($f in $Features) {
            # Remove Case Sensitivity of ordered Dictionary or Hashtables
            $f = @{}+$f

            $executionName = $f.Name -replace '\(|\)|\.| ', ''
            $executionName = "ChocolateyFeature_$executionName"
            if (-not $f.ContainsKey('Ensure')) {
                $f.Ensure = 'Present'
            }
            (Get-DscSplattedResource -ResourceName ChocolateyFeature -ExecutionName $executionName -Properties $f -NoInvoke).Invoke($f)
        }
    }

    if( $Sources -ne $null ) {
        foreach ($s in $Sources) {
            $executionName = $s.Name -replace '\(|\)|\.| ', ''
            $executionName = "Choco_Source_$executionName"

            if (-not $s.ContainsKey('Ensure')) {
                $s.Ensure = 'Present'
            }

            #if( $Features -ne $null ) {
            #    $f = $Features[0]
            #    $featureName = $f.Name
            #    $s.DependsOn = "[ChocolateyFeature]ChocolateyFeature_$featureName"
            #} else
            if ( $Software -ne $null ) {
                $s.DependsOn = "[ChocolateySoftware]$chocoSwExecName"
            }

            (Get-DscSplattedResource -ResourceName ChocolateySource -ExecutionName $executionName -Properties $s -NoInvoke).Invoke($s)
        }
    }

    if( $Packages -ne $null ){
        foreach ($p in $Packages) {
            # Remove Case Sensitivity of ordered Dictionary or Hashtables
            $p = @{}+$p

            $executionName = $p.Name -replace '\(|\)|\.| ', ''
            $executionName = "Chocolatey_$executionName"
            $p.ChocolateyOptions = [hashtable]$p.ChocolateyOptions

            if (-not $p.ContainsKey('Ensure')) {
                $p.Ensure = 'Present'
            }

            if( $Software -ne $null ) {
                $p.DependsOn = "[ChocolateySoftware]$chocoSwExecName"
            }

            [boolean]$forceReboot = $false
            if ($p.ContainsKey('ForceReboot')) {
                $forceReboot = $p.ForceReboot
                $p.Remove( 'ForceReboot' )
            }

            (Get-DscSplattedResource -ResourceName ChocolateyPackage -ExecutionName $executionName -Properties $p -NoInvoke).Invoke($p)

            if ($forceReboot -eq $true)
            {
                $rebootKeyName = 'HKLM:\SOFTWARE\DSC Community\CommonTasks\RebootRequests'
                $rebootVarName = "RebootAfter_$executionName"

                Script $rebootVarName
                {
                    TestScript = {
                        $val = Get-ItemProperty -Path $using:rebootKeyName -Name $using:rebootVarName -ErrorAction SilentlyContinue

                        if ($val -ne $null -and $val.$rebootVarName -gt 0) {
                            return $true
                        }
                        return $false
                    }
                    SetScript = {
                        if( -not (Test-Path -Path $using:rebootKeyName) ) {
                            New-Item -Path $using:rebootKeyName -Force
                        }
                        Set-ItemProperty -Path $rebootKeyName -Name $using:rebootVarName -value 1
                        $global:DSCMachineStatus = 1
                    }
                    GetScript = { return @{result = 'result'}}
                    DependsOn = "[ChocolateyPackage]$executionName"
                }
            }
        }
    }

<#
    if( $Features -ne $null ) {
        Write-Verbose "Features ne null"
        foreach ($f in $Features) {
            $executionName = $f.Name -replace '\(|\)|\.| ', ''
            $executionName = "ChocolateyFeature_$executionName"
            Write-Verbose "executionName $executionName"

            foreach ($key in $f.Keys) {
                $value = $f[$key]
                Write-Verbose " key $key value $value"
            }

            if (-not $f.ContainsKey('Ensure')) {
                $f.Ensure = 'Present'
            }
            # Added
            [boolean]$forceReboot = $false
            if ($f.ContainsKey('ForceReboot')) {
                $forceReboot = $f.ForceReboot
                $f.Remove( 'ForceReboot' )
            }
            Write-Verbose "Force reboot $forceReboot"

            (Get-DscSplattedResource -ResourceName ChocolateyFeature -ExecutionName $executionName -Properties $f -NoInvoke).Invoke($f)
            #$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
            #Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
            #refreshenv

            # Copied from $Packages section

            if ($forceReboot -eq $true)
            {
                $rebootKeyName = 'HKLM:\SOFTWARE\DSC Community\CommonTasks\RebootRequests'
                $rebootVarName = "RebootAfter_$executionName"

                Script $rebootVarName
                {
                    TestScript = {
                        $val = Get-ItemProperty -Path $using:rebootKeyName -Name $using:rebootVarName -ErrorAction SilentlyContinue

                        if ($val -ne $null -and $val.$rebootVarName -gt 0) {
                            return $true
                        }
                        return $false
                    }
                    SetScript = {
                        if( -not (Test-Path -Path $using:rebootKeyName) ) {
                            New-Item -Path $using:rebootKeyName -Force
                        }
                        Set-ItemProperty -Path $rebootKeyName -Name $using:rebootVarName -value 1
                        #$global:DSCMachineStatus = 1
                    }
                    GetScript = { return @{result = 'result'}}
                    DependsOn = "[ChocolateyFeature]$executionName"
                }

            }

        }
    }
#>
}
