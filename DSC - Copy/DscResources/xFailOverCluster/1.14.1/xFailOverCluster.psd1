@{

moduleVersion = '1.14.1'

GUID = '026e7fd8-06dd-41bc-b373-59366ab18679'

Author = 'DSC Community'

CompanyName = 'DSC Community'

Copyright = 'Copyright the DSC Community contributors. All rights reserved.'

Description = 'Module containing DSC resources for deployment and configuration of Windows Server Failover Cluster.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Functions to export from this module
FunctionsToExport = @()

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module
AliasesToExport = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{
        # Set to a prerelease string value if the release should be a prerelease.
        Prerelease = ''

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PowerShell/xFailOverCluster/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/xFailOverCluster'

        # A URL to an icon representing this module.
        IconUri = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

        # ReleaseNotes of this module
        ReleaseNotes = '# Change log for xFailOverCluster

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).

## [Unreleased]

### Changed

- xFailOverCluster
  - Changed the pipeline to publish test results for both success and failure.

### Fixed

- CommonResourceHelper
  - Fix unit tests to load the helper modules using module manifest.
  - Fix to correctly export the functions in the helper module
    ([issue #214](https://github.com/dsccommunity/xFailOverCluster/issues/214)).
  - Fix typo in module manifest.

## [1.14.0] - 2019-12-17

### Added

- xFailOverCluster
  - Added automatic release with a new CI pipeline.

### Changed

- xFailOverCluster
  - Moved the helper module `CommonResourceHelper` to the `Modules` folder.
- CommonResourceHelper
  - Update `Get-LocalizedData` to handle new location of helper module.
'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}













