﻿#requires -Version 3
function Set-RubrikModuleOption
{
  <#
      .SYNOPSIS
      Sets an option value within the users option file

      .DESCRIPTION
      The Set-RubrikModuleOption will set an option value within the users option value and immidiately apply the change.

      .NOTES
      Written by Mike Preston for community usage
      Twitter: @mwpreston
      GitHub: mwpreston

      .LINK
      https://rubrik.gitbook.io/rubrik-sdk-for-powershell/command-documentation/reference/set-rubrikmoduleoption

      .EXAMPLE
      Set-RubrikModuleOption -Type DefaultParameterValue -OptionName PrimaryClusterId -OptionValue local

      Sets the PrimaryClusterId value to always equate to local when not specified

      .EXAMPLE
      Set-RubrikModuleOption -Type ModuleOption -OptionName ApplyCustomViewDefinitions -OptionValue $false

      Sets the ApplyCustomViewDefinitions option to false, restricting custom typenames from being shown

      .EXAMPLE
      Set-RubrikModuleOption -Defaults
      Removes any custom defined options and resets to default values.
  #>

   [CmdletBinding()]
  Param(
    # Option Name
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$OptionName,
    [Parameter()]
    [string]$OptionValue
  )
  Process {
    # if name doesn't exist, exit
    if ( -not $global:rubrikOptions.ModuleOption.$OptionName) {
      throw "$OptionName doesn't exist in options file."
    }

    # update users options file with new value
    $global:rubrikOptions.ModuleOption.$OptionName = $OptionValue
    $global:rubrikOptions | ConvertTO-Json | Out-File $Home\rubrik_sdk_for_powershell_options.json

  } # End of process
} # End of function