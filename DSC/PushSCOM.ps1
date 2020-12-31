$ActionAccountCredential = Get-Credential

# Where is $ConfigData supposed to be used?
$ConfigData = @{
   AllNodes = @(
	   # Why are there two rows with NodeName specified?
      @{ NodeName = '*'; PsDscAllowPlainTextPassword = $true },
      @{ NodeName = 'v26267ncec201' }
   )
}

Configuration MMAgentConfiguration {
   Import-DscResource -ModuleName cMMAgent
  Node $AllNodes.NodeName {
     cMMAgentManagementGroups MMAgentManagementGrup {
        ManagementGroupName = 'EPAORDSCOM'
        ManagementServerName = 'V26267NCSP520'
        ActionAccountCredential = $ActionAccountCredential
        Ensure = 'Present'
     }
   }
}
# I presume this is how you call it:
MMAgentConfiguration