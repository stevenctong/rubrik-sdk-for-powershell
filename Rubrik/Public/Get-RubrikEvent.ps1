#requires -Version 3
function Get-RubrikEvent
{
  <#
      .SYNOPSIS
      Retrieve information for events that match the value specified in any of the following categories: type, status, or ID, and limit events by date.

      .DESCRIPTION
      The Get-RubrikEvent cmdlet is used to pull a event data set from a Rubrik cluster. There are a vast number of arguments
      that can be supplied to narrow down the event query.

      .NOTES
      Written by J.R. Phillips for community usage
      GitHub: JayAreP

      .LINK
      https://rubrik.gitbook.io/rubrik-sdk-for-powershell/command-documentation/reference/get-rubrikevent

      .EXAMPLE
      Get-RubrikEvent -ObjectName "vm-foo" -EventType Backup

      This will query for any 'Backup' events on the Rubrik VM object named 'vm-foo'

      .EXAMPLE
      Get-RubrikVM -Name jbrasser-win | Get-RubrikEvent -Limit 10

      Queries the Rubrik Cluster for any vms named jbrasser-win and return the last ten events for each VM found

      .EXAMPLE
      Get-RubrikEvent -EventType Archive -Limit 100

      This will query the latest 100 Archive events on the currently logged in Rubrik cluster

      .EXAMPLE
      Get-RubrikHost -Name SQLFoo.demo.com | Get-RubrikEvent

      This will feed any events against the Rubrik Host object 'SQLFoo.demo.com' via a piped query.

      .EXAMPLE
      Get-RubrikEvent -EventSeriesId '1111-2222-3333'

      This will retrieve all of the events belonging to the specified EventSeriesId. *Note - This will call Get-RubrikEventSeries*

      .EXAMPLE
      Get-RubrikEvent -EventType Archive -Limit 10 -IncludeEventSeries

      This will query the latest 10 Archive events on the currently logged in Rubrik cluster and include the relevant EventSeries.

      .EXAMPLE
      Get-RubrikEvent -Limit 25 -ExcludeObjectType AggregateAhvVm,Mssql -Verbose

      This will retrieve all of the events while excluding events of the AggregateAhvVm & Mssql object types while displaying verbose messages. This will potentially display less than 25 objects, as filtering happens after receiving the objects from the endpoint

      .EXAMPLE
      Get-RubrikEvent -Limit 25 -ExcludeEventType Archive,Replication,Configuration,Backup

      This will retrieve all of the events while excluding events of the Archive,Replication,Configuration,Backup Event types while displaying verbose messages. This will potentially display less than 25 objects, as filtering happens after receiving the objects from the endpoint

      .EXAMPLE
      Get-RubrikEvent -Limit 25 -EventType Archive -ExcludeObjectType AggregateAhvVm,Mssql -Verbose

      This will retrieve all Archive events while excluding events of the AggregateAhvVm & Mssql object types while displaying verbose messages. This will potentially display less than 25 objects, as filtering happens after receiving the objects from the endpoint
  #>

  [CmdletBinding()]
  Param(
    # Maximum number of events retrieved, default is to return 50 objects
    [Parameter(ParameterSetName="eventByID")]
    [int]$Limit = 50,
    # Earliest event retrieved
    [Alias('after_id')]
    [Parameter(ParameterSetName="eventByID")]
    [string]$AfterId,
    # Filter by Event Series ID
    [Alias('event_series_id')]
    [Parameter(ParameterSetName='EventSeries',Mandatory=$true)]
    [string]$EventSeriesId,
    # Filter by Status. Enter any of the following values: 'Failure', 'Warning', 'Running', 'Success', 'Canceled', 'Canceling’.
    [ValidateSet('Failure', 'Warning', 'Running', 'Success', 'Canceled', 'Canceling', 'Queued', IgnoreCase = $false)]
    [Parameter(ParameterSetName="eventByID")]
    [string]$Status,
    # Filter by Event Type.
    [ValidateSet('Archive', 'Audit', 'AuthDomain', 'AwsEvent', 'Backup', 'Classification', 'CloudNativeSource', 'CloudNativeVm', 'Configuration', 'Connection', 'Conversion', 'Diagnostic', 'Discovery', 'Failover', 'Fileset', 'Hardware', 'HostEvent', 'HypervScvmm', 'HypervServer', 'Instantiate', 'LegalHold', 'Maintenance', 'NutanixCluster', 'Recovery', 'Replication', 'Storage', 'StorageArray', 'StormResource', 'Support', 'System', 'TestFailover', 'Upgrade', 'VCenter', 'Vcd', 'VolumeGroup', 'UnknownEventType', IgnoreCase = $false)]
    [Alias('event_type')]
    [Parameter(ParameterSetName="eventByID")]
    [string]$EventType,
    # Filter by excluding specific Event Types, multiple entries are allowed. Note that this filtering happens after receiving the results, this means that if a limit of 50 is specified 50 or less results will be returned
    [ValidateSet('Archive', 'Audit', 'AuthDomain', 'AwsEvent', 'Backup', 'Classification', 'CloudNativeSource', 'CloudNativeVm', 'Configuration', 'Connection', 'Conversion', 'Diagnostic', 'Discovery', 'Failover', 'Fileset', 'Hardware', 'HostEvent', 'HypervScvmm', 'HypervServer', 'Instantiate', 'LegalHold', 'Maintenance', 'NutanixCluster', 'Recovery', 'Replication', 'Storage', 'StorageArray', 'StormResource', 'Support', 'System', 'TestFailover', 'Upgrade', 'VCenter', 'Vcd', 'VolumeGroup', 'UnknownEventType', IgnoreCase = $false)]
    [Parameter(ParameterSetName="eventByID")]
    [string[]]$ExcludeEventType,
    # Filter by a comma separated list of object IDs.
    [Alias('object_ids')]
    [Parameter(ValueFromPipelineByPropertyName = $true,ParameterSetName="eventByID")]
    [array]$id,
    # Filter all the events according to the provided name using infix search for resources and exact search for usernames.
    [Alias('object_name')]
    [Parameter(ParameterSetName="eventByID")]
    [string]$ObjectName,
    # Filter all the events before a date.
    [Alias('before_date')]
    [Parameter(ParameterSetName="eventByID")]
    [System.DateTime]$BeforeDate,
    # Filter all the events after a date.
    [Alias('after_date')]
    [Parameter(ParameterSetName="eventByID")]
    [System.DateTime]$AfterDate,
    # Filter all the events by object type. Enter any of the following values: 'VmwareVm', 'Mssql', 'LinuxFileset', 'WindowsFileset', 'WindowsHost', 'LinuxHost', 'StorageArrayVolumeGroup', 'VolumeGroup', 'NutanixVm', 'Oracle', 'AwsAccount', and 'Ec2Instance'. WindowsHost maps to both WindowsFileset and VolumeGroup, while LinuxHost maps to LinuxFileset and StorageArrayVolumeGroup.
    [ValidateSet('AggregateAhvVm', 'AggregateAwsAzure', 'AggregateHypervVm', 'AggregateLinuxUnixHosts', 'AggregateNasShares', 'AggregateOracleDb', 'AggregateStorageArrays', 'AggregateVcdVapps', 'AggregateVsphereVm', 'AggregateWindowsHosts', 'AppBlueprint', 'AuthDomain', 'AwsAccount', 'AwsEventType', 'Certificate', 'Cluster', 'DataLocation', 'Ec2Instance', 'Host', 'HypervScvmm', 'HypervServer', 'HypervVm', 'JobInstance', 'Ldap', 'LinuxHost', 'LinuxFileset', 'ManagedVolume', 'Mssql', 'NasHost', 'NutanixCluster', 'NutanixVm', 'OracleDb', 'OracleHost', 'OracleRac', 'PublicCloudMachineInstance', 'SamlSso', 'ShareFileset', 'SlaDomain', 'SmbDomain', 'StorageArray', 'StorageArrayVolumeGroup', 'Storm', 'SupportBundle', 'UnknownObjectType', 'Upgrade', 'UserActionAudit', 'Vcd', 'VcdVapp', 'Vcenter', 'VmwareVm', 'VolumeGroup', 'WindowsHost', 'WindowsFileset', IgnoreCase = $false)]
    [Alias('object_type')]
    [Parameter(ParameterSetName="eventByID")]
    [string]$ObjectType,
    # Filter by excluding specific Object Types, multiple entries are allowed. Note that this filtering happens after receiving the results, this means that if a limit of 50 is specified 50 or less results will be returned
    [ValidateSet('AggregateAhvVm', 'AggregateAwsAzure', 'AggregateHypervVm', 'AggregateLinuxUnixHosts', 'AggregateNasShares', 'AggregateOracleDb', 'AggregateStorageArrays', 'AggregateVcdVapps', 'AggregateVsphereVm', 'AggregateWindowsHosts', 'AppBlueprint', 'AuthDomain', 'AwsAccount', 'AwsEventType', 'Certificate', 'Cluster', 'DataLocation', 'Ec2Instance', 'Host', 'HypervScvmm', 'HypervServer', 'HypervVm', 'JobInstance', 'Ldap', 'LinuxHost', 'LinuxFileset', 'ManagedVolume', 'Mssql', 'NasHost', 'NutanixCluster', 'NutanixVm', 'OracleDb', 'OracleHost', 'OracleRac', 'PublicCloudMachineInstance', 'SamlSso', 'ShareFileset', 'SlaDomain', 'SmbDomain', 'StorageArray', 'StorageArrayVolumeGroup', 'Storm', 'SupportBundle', 'UnknownObjectType', 'Upgrade', 'UserActionAudit', 'Vcd', 'VcdVapp', 'Vcenter', 'VmwareVm', 'VolumeGroup', 'WindowsHost', 'WindowsFileset', IgnoreCase = $false)]
    [Parameter(ParameterSetName="eventByID")]
    [string[]]$ExcludeObjectType,
    # A switch value that determines whether to show only on the most recent event in the series. When 'true' only the most recent event in the series are shown. When 'false' all events in the series are shown. The default value is 'true'. Note: Deprecated in 5.2
    [Alias('show_only_latest')]
    [Parameter(ParameterSetName="eventByID")]
    [Switch]$ShowOnlyLatest,
    # A Switch value that determines whether to filter only on the most recent event in the series. When 'true' only the most recent event in the series are filtered. When 'false' all events in the series are filtered. The default value is 'true'. Note: Deprecated in 5.2
    [Alias('filter_only_on_latest')]
    [Parameter(ParameterSetName="eventByID")]
    [Switch]$FilterOnlyOnLatest,
    # A Switch value that determines whether or not EventSeries events are included in the results
    [Alias('should_include_event_series')]
    [Parameter(ParameterSetName="eventByID")]
    [Switch]$IncludeEventSeries,
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

    if (-not $EventSeriesId) {
      # If the switch parameter was not explicitly specified remove from query params
      if(-not $PSBoundParameters.ContainsKey('ShowOnlyLatest')) { $Resources.Query.Remove('show_only_latest') }
      if(-not $PSBoundParameters.ContainsKey('FilterOnlyOnLatest')) { $Resources.Query.Remove('filter_only_on_latest') }


      $uri = New-URIString -server $Server -endpoint ($resources.URI)
      $uri = Test-QueryParam -querykeys ($resources.Query.Keys) -parameters ((Get-Command $function).Parameters.Values) -uri $uri
      $body = New-BodyString -bodykeys ($resources.Body.Keys) -parameters ((Get-Command $function).Parameters.Values)

      $result = Submit-Request -uri $uri -header $Header -method $($resources.Method) -body $body



      if (($rubrikConnection.version.substring(0,5) -as [version]) -ge [version]5.2) {
        if ($FilterOnlyOnLatest) {
          Write-Warning -Message 'This switch ''FilterOnlyOnLatest'' is no longer available in versions of Rubrik CDM later than 5.2'
        }

        if ($ShowOnlyLatest) {
          Write-Warning -Message 'This switch ''ShowOnlyLatest'' is no longer available in versions of Rubrik CDM later than 5.2'
        }

        # Build Custom Object based on information in latestEvent property
        $result = $result.data | ForEach-Object {
          $CurrentObject = $_

          $Hash = [ordered]@{}
          $_.latestEvent.psobject.properties.name | ForEach-Object {
            $Hash.$_ = $CurrentObject.latestEvent.$_
          }

          $_.psobject.properties.name | Where-Object {$_ -ne 'latestEvent'} | ForEach-Object {
            $Hash.$_ = $CurrentObject.$_
          }

          if ($ExcludeEventType -and $ExcludeEventType -notcontains $Hash.eventType) {
            [pscustomobject]$Hash
          } elseif ($ExcludeEventType) {
            # No output
          } elseif ($ExcludeObjectType -and $ExcludeObjectType -notcontains $Hash.objectType) {
            [pscustomobject]$Hash
          } elseif ($ExcludeObjectType) {
            # No Output
          } else {
            [pscustomobject]$Hash
          }
        }
      } else {
        $result = Test-ReturnFormat -api $api -result $result -location $resources.Result
        $result = Test-FilterObject -filter ($resources.Filter) -result $result
      }


    } else {
      # Adding property for TypeName support
      $result = ((Get-RubrikEventSeries -id $EventSeriesId).eventDetailList) | Select-Object *,@{N="eventStatus";E={$_.status}}
    }
    
    # Add 'date' property to the output by converting 'time' property to datetime object
    if (($null -ne $result) -and ($null -ne ($result | Select-Object -First 1).time)) {
      $result = $result | ForEach-Object {
        Select-Object -InputObject $_ -Property *,@{
          name = 'date'
          expression = {Convert-APIDateTime -DateTimeString $_.time}
          }
        }
      }
    $result = Set-ObjectTypeName -TypeName $resources.ObjectTName -result $result
    return $result

  } # End of process
} # End of function