# https://docs.microsoft.com/en-us/powershell/scripting/dsc/resources/authoringresourceclass?view=powershell-7.1

enum Ensure
{
    Absent
    Present
}

[DscResource()]
class ChocoFeature
{

	[DscProperty(Key)]
	[string]$Name

	[DscProperty(Mandatory)]
	[Ensure] $Ensure

	#[DscProperty(Mandatory)]
	#[string] $SourcePath

	#[DscProperty(NotConfigurable)]
	#[Nullable[datetime]] $CreationTime

	<#
        This method is equivalent of the Set-TargetResource script function.
        It sets the resource to the desired state.
    #>
    [void] Set()
    {
        Write-Verbose "about to set $($this.Name)"
		choco feature enable -n $this.Name
    }

    <#
        This method is equivalent of the Test-TargetResource script function.
        It should return True or False, showing whether the resource
        is in a desired state.
    #>
    [bool] Test()
    {
        $FeatureName = $this.Name
        Write-Verbose "abt to test $FeatureName"
        $present = (choco feature |where-object {$_ -match "\[(.?)\] $FeatureName"})[1] -eq 'x'
        Write-Verbose "present = $present"
        if ($this.Ensure -eq [Ensure]::Present) {
            return $present
        } else {
            return -not $present
        }
    }

    <#
        This method is equivalent of the Get-TargetResource script function.
        The implementation should use the keys to find appropriate resources.
        This method returns an instance of this class with the updated key
         properties.
    #>
    [ChocoFeature] Get()
    {
        #$present = $this.TestFeaturePresence($this.Path)
        Write-Verbose "abot to Get - set absent"
        $this.Ensure = [Ensure]::Absent
<#
        if ($present)
        {
            $file = Get-ChildItem -LiteralPath $this.Path
            $this.CreationTime = $file.CreationTime
            $this.Ensure = [Ensure]::Present
        }
        else
        {
            $this.CreationTime = $null
            $this.Ensure = [Ensure]::Absent
        }
#>
        return $this
    }
} # This module defines a class for a DSC "ChocoFeature" provider.