#requires -Version 2
$ErrorActionPreference = "Stop"

function Test-BackConnectionHostNames (
    $Hostname
) {
    ExecuteTest `
        -AssertionMessage "BackConnectionHostNames registry key contains $Hostname" `
        -TestScript {
            if ((Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa).DisableLoopbackCheck) {
                Write-Verbose "Loopback checks are disabled."
                return $true
            }
            $BackConnectionHostNames = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0).BackConnectionHostNames
            if ($BackConnectionHostNames -contains $Hostname)
            {
                Write-Verbose "BackConnectionHostNames contains $Hostname"
                return $true
            }
            Write-Verbose "BackConnectionHostNames registry value is $Hostname"
            Write-TSProblem "BackConnectionHostNames registry key does not contain $Hostname."
            return $false
        } `
        -FixScript {
            Write-TSFix "Adding $Hostname to BackConnectionHostNames registry key."
            $BackConnectionHostNames = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0).BackConnectionHostNames
            if ($BackConnectionHostNames -eq $null)
            {
                $BackConnectionHostNames = "$Hostname"
            }
            else
            {
                $BackConnectionHostNames += "$Hostname"
            }
            Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0 -Name BackConnectionHostNames -Value ([String[]]@($BackConnectionHostNames))
        }
}