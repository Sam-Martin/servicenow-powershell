function New-ServiceNowConfigurationItem {
<#
.SYNOPSIS
    Generates a new ServiceNow Configuration Item
.DESCRIPTION
    Generates a new ServiceNow Configuration Item using predefined or custom fields by invoking the ServiceNow API
.LINK
    https://github.com/Sam-Martin/servicenow-powershell
.EXAMPLE
    Generate a "Network Gear" configuration item with category and subcategory set
        New-ServiceNowConfigurationItem -Name "Automation SW1" -Class "Network Gear" -CustomFields @{ category = "Hardware"; subcategory = "Switch" }
 #>
    [CmdletBinding(DefaultParameterSetName)]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        #The class of the CI
        [parameter(mandatory=$false)]
        [string]$Class,

        # custom fields as hashtable
        [parameter(mandatory=$false)]
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
    $DefinedIncidentParameters = @('Class', 'Name')
    $TableEntryValues = @{}
    ForEach ($Parameter in $DefinedIncidentParameters) {
        If ($null -ne $PSBoundParameters.$Parameter) {
            # Turn the defined parameter name into the ServiceNow attribute name
            $KeyToAdd = Switch ($Parameter) {
                Class           {'sys_class_name'; break}
                Name            {'name'; break}
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
        Table = 'cmdb_ci'
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
