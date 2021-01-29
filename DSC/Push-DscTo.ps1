<#
.SYNOPSIS
    Push pre-built DSC config to target server
.TITLE
    Get-DscTo.ps1
.DESCRIPTION
	Force target server into new DSC config
.PARAMETERS
	[-SourceRoot e:\chiz\dsc\Try2\DscWorkshop\DSC]
	-Computer v26267ncec201
.NOTES

.AUTHOR
	Kevin Weinrich, Vision Technologies
#>

[CmdletBinding()]
Param([string]$SourceRoot = 'e:\chiz\dsc\Try2\DscWorkshop\DSC'
	,[string]$Computer = 'v26267ncec201'
)
# StrictMode has to come after CmdletBinding
Set-StrictMode -version 2

# If variable doesn't exist, set up a new connection
if (!(get-variable cimsessionTarget -erroraction SilentlyContinue)) {
	$cimsessionTarget = new-CimSession $Computer
}
# What does the LCM look like before we start?
Get-DscLocalConfigurationManager -CimSession $cimsessionTarget

# Push LCM config
Set-DscLocalConfigurationManager -Path $SourceRoot\BuildOutput\MetaMof -Verbose -CimSession $cimsessionTarget
# What does the LCM look like after we have pushed it?
Get-DscLocalConfigurationManager -CimSession $cimsessionTarget

# Push DSC config
if (!(get-variable pssessionTarget -erroraction SilentlyContinue) -or ($pssessionTarget.state -ne 'open')) {
	$pssessionTarget = New-PSSession $Computer
}
Push-DscConfiguration -session $pssessionTarget -MOF $SourceRoot\BuildOutput\MOF\$Computer.mof `
 -DSCBuildOutputModules $SourceRoot\BuildOutput\ModulesNew -RemoteStagingPath C:\temp -Verbose `
 -WithModule (Get-ModuleFromFolder c:\users\kevin.weinrich\Documents\WindowsPowerShell\Modules) -Confirm:$false

# -WithModule (Get-ModuleFromFolder c:\users\kevin.weinrich\Documents\WindowsPowerShell\Modules) -Confirm:$false

# What does the LCM look like after we have pushed the DSC?
Get-DscLocalConfigurationManager -CimSession $cimsessionTarget