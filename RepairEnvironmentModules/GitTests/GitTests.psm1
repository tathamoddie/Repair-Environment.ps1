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

function Test-GitHookInstalled (
    $HookName,
    $InstallScriptPath
) {
    ExecuteTest `
        -AssertionMessage "Git hook $HookName is installed" `
        -TestScript {
            $GitRepoRoot = (& git rev-parse --show-toplevel)
            if (-not $?)
            {
                Write-TSProblem "Couldn't find the git repository root: git rev-parse --show-toplevel failed"
                return $false
            }
            $GitFolder = Join-Path $GitRepoRoot '.git'
            if (-not (Test-Path $GitFolder))
            {
                Write-TSProblem "Couldn't find the .git folder that we expected to see at $GitFolder"
                return $false
            }
            $HookPath = Join-Path $GitFolder "hooks\$HookName"
            if (Test-Path $HookPath)
            {
                Write-Verbose "$HookPath exists; $HookName hook is installed"
                return $true
            }
            Write-TSProblem "Git $HookName hook not installed at $HookPath"
            return $false
        } `
        -FixScript {
            Write-TSFix "Installing Git $HookName hook using $InstallScriptPath"
            & $InstallScriptPath
        }
}

function Test-GitVersion
{
    param
    (
        [string] $MinimumVersion
    )

    ExecuteTest `
        -AssertionMessage "Git version is higher than or equal to $MinimumVersion" `
        -TestScript `
        {
            $fullVersionString = (git --version)
            if ($fullVersionString -notmatch "\d+(\.\d+)+")
            {
                Write-TSProblem "Git version $fullVersionString does not have numeric part"
                return $false
            }

            $versionNumberString = $matches[0]

            if (Test-VersionHigherOrEqual -Current $versionNumberString -Minimum $MinimumVersion)
            {
                Write-Verbose "Git version $versionNumberString is higher than or equal to $MinimumVersion"
                return $true
            }

            Write-TSProblem "Git version $versionNumberString is lower than $MinimumVersion"
            return $false
        }
}

function Test-VersionHigherOrEqual
{
    param
    (
        [string] $Current,
        [string] $Minimum
    )

    $currentParts = $Current -split "\."
    $minimumParts = $Minimum -split "\."

    for ($i = 0; ($i -lt $currentParts.Length) -and ($i -lt $minimumParts.Length); $i++)
    {
        $currentPartDigit = [int] $currentParts[$i]
        $minimumPartDigit = [int] $minimumParts[$i]

        if ($currentPartDigit -gt $minimumPartDigit)
        {
            return $true
        }
        elseif ($currentPartDigit -lt $minimumPartDigit)
        {
            return $false
        }
    }

    return $true
}