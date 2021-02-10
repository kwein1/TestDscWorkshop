#Region './Private/Get-DatumCurrentNode.ps1' 0
function Get-DatumCurrentNode
{
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $fileNode = $File | Get-Content | ConvertFrom-Yaml
    $rsopNode = Get-DatumRsop -Datum $datum -AllNodes $currentNode

    if ($rsopNode)
    {
        $rsopNode
    }
    else
    {
        $fileNode
    }
}
#EndRegion './Private/Get-DatumCurrentNode.ps1' 20
#Region './Private/Resolve-DatumDynamicPart.ps1' 0
function Resolve-DatumDynamicPart
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ExpandableString', 'ScriptBlock')]
        [string]$DatumType
    )

    if (-not $datum -and -not $DatumTree)
    {
        return $InputObject
    }
    elseif (-not $datum -and $DatumTree)
    {
        $datum = $DatumTree
    }

    if ((Get-PSCallStack | Select-Object -Skip 1).Command -contains $MyInvocation.MyCommand.Name)
    {
        return $InputObject
    }

    try
    {
        $command = [scriptblock]::Create($InputObject)
        if ($DatumType -eq 'ScriptBlock')
        {
            & (& $command)
        }
        else
        {
            & $command
        }
    }
    catch
    {
        Write-Error -Message ($script:localizedData.CannotCreateScriptBlock -f $InputObject, $_.Exception.Message)
        return $InputObject
    }
}    $command = [scriptblock]::Create($command)
#EndRegion './Private/Resolve-DatumDynamicPart.ps1' 44
#Region './Public/Invoke-InvokeCommandAction.ps1' 0
function Invoke-InvokeCommandAction
{
    <#
    .SYNOPSIS
    Call the scriptblock that is given via Datum.

    .DESCRIPTION
    When Datum uses this handler to invoke whatever script block is given to it. The returned
    data is used as configuration data.

    .PARAMETER InputObject
    Script block to invoke

    .PARAMETER Header
    Header of the Datum data string that encapsulates the script block.
    The default is [Command= but can be customized (i.e. in the Datum.yml configuration file)

    .PARAMETER Footer
    Footer of the Datum data string that encapsulates the encrypted data. The default is ]

    .EXAMPLE
    $command | Invoke-ProtectedDatumAction

    .NOTES
    The arguments you can set in the Datum.yml is directly related to the arguments of this function.

    #>
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InputObject,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [object]
        $Node,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.IO.FileInfo]
        $File
    )

    if ($result = ($datumInvokeCommandRegEx.Match($InputObject).Groups['Content'].Value))
    {
        if ($datumType = 
            & {
                $errors = $null
                $tokens = $null

                $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                    $result,
                    [ref]$tokens,
                    [ref]$errors
                )

                if (($tokens[0].Kind -eq 'LCurly' -and $tokens[-2].Kind -eq 'RCurly' -and $tokens[-1].Kind -eq 'EndOfInput') -or
                    ($tokens[0].Kind -eq 'LCurly' -and $tokens[-3].Kind -eq 'RCurly' -and $tokens[-2].Kind -eq 'NewLine' -and $tokens[-1].Kind -eq 'EndOfInput'))
                {
                    'ScriptBlock'
                }
                elseif ($tokens |
                        & {
                            process
                            {
                                if ($_.Kind -eq 'StringExpandable')
                                {
                                    $_
                                }
                            }
                        })
                {
                    'ExpandableString'
                }
                else
                {
                    $false
                }
            })
        {
            if (-not $Node -and $File)
            {
                if ($File.Name -ne 'Datum.yml')
                {
                    $Node = Get-DatumCurrentNode -File $File

                    if (-not $Node)
                    {
                        return $InputObject
                    }
                }
            }

            Resolve-DatumDynamicPart -InputObject $result -DatumType $datumType
        }
        else
        {
            $InputObject
        }
    }
    else
    {
        $InputObject
    }
}
#EndRegion './Public/Invoke-InvokeCommandAction.ps1' 105
#Region './Public/Test-InvokeCommandFilter.ps1' 0
function Test-InvokeCommandFilter
{
    <#
    .SYNOPSIS
    Filter function to verify if it's worth triggering the action for the data block.

    .DESCRIPTION
    This function is run in the ConvertTo-Datum function of the Datum module on every pass,
    and when it returns true, the action of the handler is called.

    .PARAMETER InputObject
    Object to test to decide whether to trigger the action or not

    .EXAMPLE
    $object | Test-ProtectedDatumFilter

    #>
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]
        $InputObject
    )

    $InputObject -is [string] -and $datumInvokeCommandRegEx.Match($InputObject.Trim()).Groups['Content'].Value
}
#EndRegion './Public/Test-InvokeCommandFilter.ps1' 26
