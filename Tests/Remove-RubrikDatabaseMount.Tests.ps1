Remove-Module -Name 'Rubrik' -ErrorAction 'SilentlyContinue'
Import-Module -Name './Rubrik/Rubrik.psd1' -Force

foreach ( $privateFunctionFilePath in ( Get-ChildItem -Path './Rubrik/Private' | Where-Object extension -eq '.ps1').FullName  ) {
    . $privateFunctionFilePath
}

Describe -Name 'Public/Remove-RubrikDatabaseMount' -Tag 'Public', 'Remove-RubrikDatabaseMount' -Fixture {
    #region init
    $global:rubrikConnection = @{
        id      = 'test-id'
        userId  = 'test-userId'
        token   = 'test-token'
        server  = 'test-server'
        header  = @{ 'Authorization' = 'Bearer test-authorization' }
        time    = (Get-Date)
        api     = 'v1'
        version = '4.0.5'
    }
    #endregion

    Context -Name 'Parameters' {
        Mock -CommandName Test-RubrikConnection -Verifiable -ModuleName 'Rubrik' -MockWith {}
        Mock -CommandName Submit-Request -Verifiable -ModuleName 'Rubrik' -MockWith {
            @{
                'id'        = 'RESTORE_MSSQL_DB_01234567-8910-1abc-d435-0abc1234d567_01234567-8910-1abc-d435-0abc1234d567:::0'
                'status'    = 'QUEUED'
                'progress'  = '0'
                'startTime' = '2019-07-02 11:21:22 PM'
            }
        }
        It -Name 'Should return status of queued' -Test {
            ( Remove-RubrikDatabaseMount -id MssqlDatabase:::12345678-1234-abcd-8910-1234567890ab ).status |
                Should -BeExactly 'QUEUED'
        }
        Assert-VerifiableMock
        Assert-MockCalled -CommandName Test-RubrikConnection -ModuleName 'Rubrik' -Times 1
        Assert-MockCalled -CommandName Submit-Request -ModuleName 'Rubrik' -Times 1
    }

    Context -Name 'Parameter Validation' {
        It -Name 'Parameter ID cannot be $null' -Test {
            { Remove-RubrikDatabaseMount -id $null } |
                Should -Throw "Cannot validate argument on parameter 'id'"
        }
        It -Name 'Parameter ID cannot be empty' -Test {
            { Remove-RubrikDatabaseMount -id '' } |
                Should -Throw "Cannot validate argument on parameter 'id'"
        }
    }
}