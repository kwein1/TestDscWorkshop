function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )
    Write-Verbose "KWChocolateyFeature Get $Name"
    $Env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')

    Import-Module $PSScriptRoot\..\..\Chocolatey.psd1 -verbose:$False

    $FeatureConfig = Get-ChocolateyFeature -Name $Name

    return @{
        Ensure = @('Absent','Present')[[int][bool]$FeatureConfig.enabled]
        Name = $FeatureConfig.Name
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )
    $datetime = get-date
    Write-Verbose "KWChocolateyFeature Set $Name at $datetime"
    "Time to set $Name in ChocolateyFeature.psm1 is $datetime" >> c:\temp\SetChoc.txt

    $Env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')

    Import-Module $PSScriptRoot\..\..\Chocolatey.psd1 -verbose:$False

    switch ($Ensure) {
        'Present' { Enable-ChocolateyFeature -Name $Name}
        'Absent'  { Disable-ChocolateyFeature -Name $Name}
    }
    # It appears these steps aren't needed! 1/27/21
    #$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
    #Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    #refreshenv

    #if ($Name -eq 'useFipsCompliantChecksums') {
    #  $global:DSCMachineStatus = 1
    #  Write-Verbose "Having set $Name to $Ensure, now reboot"
    #}
    # It appears that a feature change needs a reboot
    #Write-Host "Having set $executionName, now reboot"
  #  $global:DSCMachineStatus = 1
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )
    #Write-Verbose "KWChocolateyFeature Test $Name"

    $Env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')

    Import-Module $PSScriptRoot\..\..\Chocolatey.psd1 -verbose:$False

    $EnsureResultMap = @{
        'Present' = $false
        'Absent'  = $true
    }
    return (Test-ChocolateyFeature -Name $Name -Disabled:($EnsureResultMap[$Ensure]))
}

Export-ModuleMember -Function *-TargetResource
