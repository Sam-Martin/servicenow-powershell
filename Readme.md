# ServiceNow

[![GitHub release](https://img.shields.io/github/release/Sam-Martin/servicenow-powershell.svg)](https://github.com/Sam-Martin/servicenow-powershell/releases/latest) [![GitHub license](https://img.shields.io/github/license/Sam-Martin/servicenow-powershell.svg)](LICENSE) ![Test Coverage](https://img.shields.io/badge/coverage-75%25-yellow.svg)

This PowerShell module provides a series of cmdlets for interacting with the [ServiceNow REST API](http://wiki.servicenow.com/index.php?title=REST_API), performed by wrapping `Invoke-RestMethod` for the API calls.

**IMPORTANT:** Neither this module nor its creator are in any way affiliated with ServiceNow.

## Version 1

The module has been renamed from PSServiceNow to ServiceNow for version 1.  This change moves us away from the reserved "PS" prefix.  Since the name change is a major change for the user base and the project was never incremented to v1 we've taken the opportunity to label it such.

In addition to the name change the following high level changes have been made:

Back End:

* The module structure has been updated to individual files for each function.
* The build process has been migrated from MAKE to psake with support of the BuildHelpers module.
* Pester testing has been expanded to cover more scenarios.
* Improved code formatting, removed aliases, fixed file encoding.

The gains are marginal in some aspects, but intended to allow for better management in the future.

Front End:

* The following fields are now returned in the DateTime format instead of string:  'closed_at','expected_start','follow_up','opened_at','sys_created_on','sys_updated_on','work_end','work_start'  [v1.0.1 Update: This process now attempts to format the property as DateTime based off your local culture settings, a universal `yyyy-MM-dd HH:mm:ss` format, and finally leaves the property as a string if those two convert attempts fail].
* The formatting of returned data has been updated across all the `Get` functions except `Get-ServiceNowTable`.  This means you'll see a handful of default properties returned and can use `Format-List` or `Select-Object` to view all other properties associated with the object.

These changes should improve your ability to filter on the right, especially by DateTime, as well as return more information in general.

## Requirements

Requires PowerShell 3.0 or above as this is when `Invoke-RestMethod` was introduced.

Requires authorization in your ServiceNow tenant.  Due to the custom nature of ServiceNow your organization may have REST access restricted.  The following are some tips to ask for if you're having to go to your admin for access:

* Out of the box tables should be accessible by granting the `ITIL` role.
* Custom tables may require adjustments to the ACL.
* The `Web_Service_Admin` role may also be an option.

## Usage

Download the [latest release](https://github.com/Sam-Martin/servicenow-powershell/releases/latest) and  extract the .psm1 and .psd1 files to your PowerShell profile directory (i.e. the `Modules` directory under wherever `$profile` points to in your PS console) and run:
`Import-Module ServiceNow`
Once you've done this, all the cmdlets will be at your disposal, you can see a full list using `Get-Command -Module ServiceNow`.

### Example - Using Set-ServiceNowAuth

```PowerShell
Set-ServiceNowAuth -url InstanceName.service-now.com -Credentials (Get-Credential)
```

The URL should be the instance name portion of the FQDN for your instance.  If you browse to `https://yourinstance.service-now.com` the URL required for the module is `yourinstance.service-now.com`.

### Example - Retrieving an Incident Containing the Word 'PowerShell'

```PowerShell
Import-Module ServiceNow
Set-ServiceNowAuth
Get-ServiceNowIncident -MatchContains @{short_description='PowerShell'}
```

### Example - Retrieving an Incident Containing the Word 'PowerShell' While Passing Authentication

```PowerShell
Import-Module ServiceNow
Get-ServiceNowIncident -MatchContains @{short_description='PowerShell'} -ServiceNowCredential $PSCredential -ServiceNowURL $ServiceNowURL
```

### Example - Update a Ticket

```PowerShell
$Incident = Get-ServiceNowIncident -Limit 1 -MatchContains @{short_description='PowerShell'}
Update-ServiceNowIncident -SysID $Incident.Sys_ID -Values @{comments='Updated via PowerShell'}
```

### Example - Creating a Incident with custom table entries

```PowerShell
$IncidentParams = @{Caller = "UserName" 
            ShortDescription = "New PS Incident" 
            Description = "This incident was created from Powershell" 
            CustomFields = @{u_service = "MyService"
                            u_incident_type = "Request"}
            }
New-ServiceNowIncident @Params
```

### Azure Connection Object (Automation Integration Module Support)

The module can use the `Connection` parameter in conjunction with the included `ServiceNow-Automation.json` file for use as an Azure automation integration module.  Details of the process is available at [Authoring Integration Modules for Azure Automation](https://azure.microsoft.com/en-us/blog/authoring-integration-modules-for-azure-automation).

The `Connection` parameter accepts a hashtable object that requires a username, password, and ServiceNowURL.

## Functions

* Add-ServiceNowAttachment
* Get-ServiceNowAttachment
* Get-ServiceNowAttachmentDetail
* Get-ServiceNowChangeRequest
* Get-ServiceNowConfigurationItem
* Get-ServiceNowIncident
* Get-ServiceNowRequest
* Get-ServiceNowRequestItem
* Get-ServiceNowTable
* Get-ServiceNowTableEntry
* Get-ServiceNowUser
* Get-ServiceNowUserGroup
* New-ServiceNowRequest
* New-ServiceNowChangeRequest
* New-ServiceNowConfigurationItem
* New-ServiceNowIncident
* New-ServiceNowQuery
* New-ServiceNowTableEntry
* Remove-ServiceNowAttachment
* Remove-ServiceNowAuth
* Remove-ServiceNowTableEntry
* Set-ServiceNowAuth
* Test-ServiceNowAuthIsSet
* Update-ServiceNowChangeRequest
* Update-ServiceNowIncident
* Update-ServiceNowNumber
* Update-ServiceNowRequestItem
* Update-ServiceNowTableEntry

## Tests

This module comes with [Pester](https://github.com/pester/Pester/) tests for unit testing.

## Scope & Contributing

This module has been created as an abstraction layer to suit my immediate requirements. Contributions are gratefully received however, so please feel free to submit a pull request with additional features or amendments.

## Development

### Building

To build the default build.

```Powershell
.\build.ps1
```

To build a specific task.

```Powershell
.\build.ps1 -Test Build
```

## Author

Author:: Sam Martin
