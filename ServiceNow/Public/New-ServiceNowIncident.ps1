function New-ServiceNowIncident{
<#
.SYNOPSIS
    Generates a new ServiceNow Incident

.DESCRIPTION
    Generates a new ServiceNow Incident using predefined or custom fields by invoking the ServiceNow API

.LINK
    https://github.com/Sam-Martin/servicenow-powershell

.EXAMPLE
    Generate a basic Incident attributed to the caller "UserName" with descriptions, categories, assignment groups and CMDB items set.
        New-ServiceNowIncident -Caller "UserName" -ShortDescription = "New PS Incident" -Description = "This incident was created from Powershell" -AssignmentGroup "ServiceDesk" -Comment "Inline Comment" -Category "Office" -Subcategory "Outlook" -ConfigurationItem UserPC1

.EXAMPLE
    Generate an Incident by "Splatting" all fields used in the 1st example plus some additional custom ServiceNow fields (These must exist in your ServiceNow Instance):

        $IncidentParams = @{Caller = "UserName"
            ShortDescription = "New PS Incident"
            Description = "This incident was created from Powershell"
            AssignmentGroup = "ServiceDesk"
            Comment = "Inline Comment"
            Category = "Office"
            Subcategory = "Outlook"
            ConfigurationItem = UserPC1
            CustomFields = @{u_custom1 = "Custom Field Entry"
                            u_another_custom = "Related Test"}
            }
        New-ServiceNowIncident @IncidentParams

 #>

    Param(

        # sys_id of the caller of the incident (user Get-ServiceNowUser to retrieve this)
        [parameter(Mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Caller,

        # Short description of the incident
        [parameter(Mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$ShortDescription,

        # Long description of the incident
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Description,

        # sys_id of the assignment group (use Get-ServiceNowUserGroup to retrieve this)
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$AssignmentGroup,

        # Comment to include in the ticket
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Comment,

        # Category of the incident (e.g. 'Network')
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Category,

        # Subcategory of the incident (e.g. 'Network')
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Subcategory,

        # sys_id of the configuration item of the incident
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$ConfigurationItem,

        # custom fields as hashtable
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [hashtable]$CustomFields,

        # Credential used to authenticate to ServiceNow
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$ServiceNowCredential,

        # The URL for the ServiceNow instance being used (eg: instancename.service-now.com)
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        #Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection
    )

    # Create a hash table of any defined parameters (not CustomFields) that have values
    $DefinedIncidentParameters = @('AssignmentGroup','Caller','Category','Comment','ConfigurationItem','Description','ShortDescription','Subcategory')
    $TableEntryValues = @{}
    ForEach ($Parameter in $DefinedIncidentParameters) {
        If ($null -ne $PSBoundParameters.$Parameter) {
            # Turn the defined parameter name into the ServiceNow attribute name
            $KeyToAdd = Switch ($Parameter) {
                AssignmentGroup     {'assignment_group'; break}
                Caller              {'caller_id'; break}
                Category            {'category'; break}
                Comment             {'comments'; break}
                ConfigurationItem   {'cmdb_ci'; break}
                Description         {'description'; break}
                ShortDescription    {'short_description'; break}
                Subcategory         {'subcategory'; break}
            }
            $TableEntryValues.Add($KeyToAdd,$PSBoundParameters.$Parameter)
        }
    }

    # Add CustomFields hash pairs to the Table Entry Values hash table
    If ($null -ne $PSBoundParameters.CustomFields) {
        $DuplicateTableEntryValues = ForEach ($Key in $CustomFields.Keys) {
            If (($TableEntryValues.ContainsKey($Key) -eq $False)) {
                # Add the unique entry to the table entry values hash table
                $TableEntryValues.Add($Key,$CustomFields[$Key])
            }
            Else {
                # Capture the duplicate key name
                $Key
            }
        }
    }

    # Throw an error if duplicate fields were provided
    If ($null -ne $DuplicateTableEntryValues) {
        $DuplicateKeyList = $DuplicateTableEntryValues -join ","
        Throw "Ticket fields may only be used once:  $DuplicateKeyList"
    }

    # Table Entry Splat
    $newServiceNowTableEntrySplat = @{
        Table = 'incident'
        Values = $TableEntryValues
    }

    # Update the splat if the parameters have values
    if ($null -ne $PSBoundParameters.Connection)
    {
        $newServiceNowTableEntrySplat.Add('Connection',$Connection)
    }
    elseif ($null -ne $PSBoundParameters.ServiceNowCredential -and $null -ne $PSBoundParameters.ServiceNowURL)
    {
        $newServiceNowTableEntrySplat.Add('ServiceNowCredential',$ServiceNowCredential)
        $newServiceNowTableEntrySplat.Add('ServiceNowURL',$ServiceNowURL)
    }

    # Create the table entry
    New-ServiceNowTableEntry @newServiceNowTableEntrySplat
}
