#requires -Version 2
$ErrorActionPreference = "Stop"

function Test-GitUserDetailsAreConfigured (
) {
    ExecuteTest `
        -AssertionMessage "Git username is configured" `
        -TestScript {
            $GitUsername = & git config user.name
            if ($GitUsername -ne $null)
            {
                Write-Verbose "Git username is $GitUsername"
                return $true
            }
            Write-TSProblem "Git username is not configured"
            return $false
        }

    ExecuteTest `
        -AssertionMessage "Git email address is configured" `
        -TestScript {
            $GitUsername = & git config user.email
            if ($GitUsername -ne $null)
            {
                Write-Verbose "Git email address is $GitUsername"
                return $true
            }
            Write-TSProblem "Git email address is not configured"
            return $false
        }
}

function Test-GitRemote (
    $RemoteName,
    $ExpectedUrl
) {
    ExecuteTest `
        -AssertionMessage "Git remote $RemoteName is $ExpectedUrl" `
        -TestScript {
            $CurrentUrl = & git config remote.$RemoteName.url
            if ($CurrentUrl -eq $ExpectedUrl)
            {
                Write-Verbose "Git remote $RemoteName is $ExpectedUrl"
                return $true
            }
            Write-TSProblem "Git remote $RemoteName is $CurrentUrl instead of the expected $ExpectedUrl"
            return $false
        } `
        -FixScript {
            Write-TSFix "Setting Git remote $RemoteName to $ExpectedUrl"
            & git config remote.$RemoteName.url "$ExpectedUrl"
        }
}
