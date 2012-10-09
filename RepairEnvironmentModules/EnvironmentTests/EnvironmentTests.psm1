#requires -Version 2
$ErrorActionPreference = "Stop"

function Test-CommandAvailableInPath (
    $CommandName
) {
    ExecuteTest `
        -AssertionMessage "$CommandName is available in system path" `
        -TestScript {
            if ((Get-Command $CommandName -ErrorAction SilentlyContinue) -ne $null)
            {
                Write-Verbose "$CommandName is available in system path"
                return $true
            }
            Write-TSProblem "$CommandName is not available in system path"
            return $false
        }
}