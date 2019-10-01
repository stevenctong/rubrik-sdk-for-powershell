#requires -Version 3
function Set-RubrikUserRole {
  <#  
      .SYNOPSIS
      Updates an existing users role

      .DESCRIPTION
      The Set-RubrikUserRole cmdlet is used modify a users role and authorizations to objects within the Rubrik cluster

      .NOTES
      Written by Mike Preston for community usage
      Twitter: @mwpreston
      GitHub: mwpreston

      .LINK
      http://rubrikinc.github.io/rubrik-sdk-for-powershell/reference/Set-RubrikUserRole.html

      .EXAMPLE
      Set-RubrikUserRole
      This will set the specified password for the user account with the specified id.

      .EXAMPLE
      Set-RubrikUserRole
      This will change the user matching the specified id last name to 'Smith'
  #>

  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
  Param(
    # User ID
    [Parameter(ParameterSetName = "Admin", Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [Parameter(ParameterSetName = "NoAccess", Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [Parameter(ParameterSetName = "EndUserAdd", Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [Parameter(ParameterSetName = "EndUserRemove", Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [Parameter(ParameterSetName = "ReadOnlyAdmin", Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias('principals')]
    [String[]]$Id,
    
    # Sets users role to Admin
    [Parameter(ParameterSetName = "Admin", Mandatory = $true)]
    [Switch]$Admin,
    

    # Sets users role to End User
    [Parameter(ParameterSetName = "EndUserAdd", Mandatory = $true)]
    [Parameter(ParameterSetName = "EndUserRemove", Mandatory = $true)]
    [Switch]$EndUser,  
    
    # Sets users role to No Access (Removes all access from user)
    [Parameter(ParameterSetName = "NoAccess", Mandatory = $true)]
    [Switch]$NoAccess,
 
        
    # Sets users role to No Access (Removes all access from user)
    [Parameter(ParameterSetName = "ReadOnlyAdmin", Mandatory = $true)]
    [Switch]$ReadOnlyAdmin,

    # Specifies -Privileges should be added to the users authorizations
    [Parameter(ParameterSetName = "EndUserAdd", Mandatory = $true)]
    [Switch]$Add,  
    
    # Specifies -Privileges should be removed from the users authorizations
    [Parameter(ParameterSetName = "EndUserRemove", Mandatory = $true)]
    [Switch]$Remove,  
    
    # Event Objects to grant or revoke access to
    [Parameter(ParameterSetName = "EndUserAdd", Mandatory = $false)]
    [Parameter(ParameterSetName = "EndUserRemove", Mandatory = $false)]
    [Alias('viewEvent')]
    [String[]]$EventObjects = @(),
    
    # Objects which can be restored, with file download disabled
    [Parameter(ParameterSetName = "EndUserAdd", Mandatory = $false)]
    [Parameter(ParameterSetName = "EndUserRemove", Mandatory = $false)]
    [Alias('restoreWithoutDownload')]
    [String[]]$RestoreWithoutDownloadObjects = @(),
    
    # Objects which can be restored, overwriting original
    [Parameter(ParameterSetName = "EndUserAdd", Mandatory = $false)]
    [Parameter(ParameterSetName = "EndUserRemove", Mandatory = $false)]
    [Alias('destructiveRestore')]
    [String[]]$RestoreWithOverwriteObjects = @(),
    
    # Objects allowing On-Demand Snapshots
    [Parameter(ParameterSetName = "EndUserAdd", Mandatory = $false)]
    [Parameter(ParameterSetName = "EndUserRemove", Mandatory = $false)]
    [Alias('onDemandSnapshot')]
    [String[]]$OnDemandSnapshotObjects = @(),
    
    # Report objects
    [Parameter(ParameterSetName = "EndUserAdd", Mandatory = $false)]
    [Parameter(ParameterSetName = "EndUserRemove", Mandatory = $false)]
    [Alias('viewReport')]
    [String[]]$ReportObjects = @(),

    # Objects which can be restored
    [Parameter(ParameterSetName = "EndUserAdd", Mandatory = $false)]
    [Parameter(ParameterSetName = "EndUserRemove", Mandatory = $false)]
    [Alias('restore')]
    [String[]]$RestoreObjects = @(),
    
    # Infrastructure Objects allowing provisioning of restores/live mounts
    [Parameter(ParameterSetName = "EndUserAdd", Mandatory = $false)]
    [Parameter(ParameterSetName = "EndUserRemove", Mandatory = $false)]
    [Alias('provisionOnInfra')]
    [String[]]$InfrastructureObjects = @(),

    # Rubrik server IP or FQDN
    [String]$Server = $global:RubrikConnection.server,
    # API version
    [String]$api = $global:RubrikConnection.api
  )

  Begin {

    # The Begin section is used to perform one-time loads of data necessary to carry out the function's purpose
    # If a command needs to be run with each iteration or pipeline input, place it in the Process section
    
    # Check to ensure that a session to the Rubrik cluster exists and load the needed header data for authentication
    Test-RubrikConnection
    
    # API data references the name of the function
    # For convenience, that name is saved here to $function
    $function = $MyInvocation.MyCommand.Name
        
    # Retrieve all of the URI, method, body, query, result, filter, and success details for the API endpoint
    Write-Verbose -Message "Gather API Data for $function"
    $resources = Get-RubrikAPIData -endpoint $function
    Write-Verbose -Message "Load API data for $($resources.Function)"
    Write-Verbose -Message "Description: $($resources.Description)"
  
  }

  Process {


    function Update-Role {
      Param ([string]$role, [string]$roleUri,[string]$roleMethod)
      $resources.Method = $roleMethod

      # Build body based on role
      switch ($role) {
        "admin" {
          $body = @{
            principals = @($id)
            privileges = @{
              fullAdmin = @("Global:::All")
            }
          } 
        }
        "end_user" {
          # Build body for end_user add/delete
          $body = @{
            principals = @($id)
            privileges = @{
              viewEvent              = $EventObjects
              restoreWithoutDownload = $RestoreWithoutDownloadObjects
              destructiveRestore     = $RestoreWithOverwriteObjects
              onDemandSnapshot       = $OnDemandSnapshotObjects
              viewReport             = $ReportObjects
              restore                = $RestoreObjects
              provisionOnInfra       = $InfrastructureObjects
            }
          }
        }
        "read_only_admin" {
          $body = @{
            principals = @($id)
            privileges = @{
              basic = @("Global:::All")
            }
          } 
        }
        "end_user_clear" {
          # Retrieve current end user privileges from user to use in deletion body
          $endUserPrivileges = (Get-RubrikUserRole -id $id).endUser
          # Set empty properties of privileges to empty array, set single results to array of 1
          # null check present in order to pass tests
          if ($null -ne $endUserPrivileges) {
            $endUserPrivileges.PSObject.Properties | ForEach-Object { 
              if ($_.Value.Count -eq 0) { $_.Value = @() }
              elseif ($_.Value.Count -eq 1) { $_.Value = @($_.Value) } 
            }
          }
          # Build body for end_user 
          $body = @{
            principals = @($id)
            privileges = $endUserPrivileges
          }
        }
      }
      $body = ConvertTO-Json $body
      $uri = New-URIString -server $Server -endpoint "$roleUri"
      $result = Submit-Request -uri $uri -header $Header -method $($resources.Method) -body $body
      $result = Test-ReturnFormat -api $api -result $result -location $resources.Result
      $result = Test-FilterObject -filter ($resources.Filter) -result $result
    }

    if ($Admin) {
      # Create Admin, leave other roles in tact
      $result = Update-Role -roleUri "$($resources.Uri)/admin" -role "admin" -roleMethod "POST"
    }
    elseif ($EndUser) {
      # Delete Admin
      $result = Update-Role -roleUri "$($resources.Uri)/admin" -role "admin" -roleMethod "DELETE"

      # Check if we are adding or removing authorizations for end user
      if ($Add) {
        $result = Update-Role -roleUri "$($resources.Uri)/end_user" -role "end_user" -roleMethod "POST"
      }
      if ($Remove) {
        $result = Update-Role -roleUri "$($resources.Uri)/end_user" -role "end_user" -roleMethod "DELETE"
      }
    }
    elseif ($ReadOnlyAdmin) {
      # Delete Admin
      $result = Update-Role -roleUri "$($resources.Uri)/admin" -role "admin" -roleMethod "DELETE"

      # Delete End User current perms
      $result = Update-Role -roleUri "$($resources.Uri)/end_user" -role "end_user_clear" -roleMethod "DELETE"

      #Add Read Only Admin
      $result = Update-Role -roleUri "$($resources.Uri)/read_only_admin" -role "read_only_admin" -roleMethod "POST"
     
    }
    elseif ($NoAccess) {
      # Delete Admin
      $result = Update-Role -roleUri "$($resources.Uri)/admin" -role "admin" -roleMethod "DELETE"
    
      # Delete End User
      $result = Update-Role -roleUri "$($resources.Uri)/end_user" -role "end_user_clear" -roleMethod "DELETE"
    
      # Delete Read Only Admin
      $result = Update-Role -roleUri "$($resources.Uri)/read_only_admin" -role "read_only_admin" -roleMethod "DELETE"
    }

    return $result

  } # End of process
} # End of function