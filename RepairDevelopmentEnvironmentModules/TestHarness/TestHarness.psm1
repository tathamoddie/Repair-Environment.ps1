#requires -Version 2
$ErrorActionPreference = "Stop"

function Write-TSProblem ([string]$Message) {
	Write-Host -Object "`nProblem: $Message" -ForegroundColor Yellow
}

function Write-TSManualStep ([string]$Message) {
	Write-Host -Object "`nManual Step: $Message" -ForegroundColor Gray
	if ($Confirm) {
		$Response = Read-Host -Prompt " Enter A to abort, anything else to continue"
		if ($Response -eq "a") { exit }
	}
}

function Write-TSFix ([string]$Message) {
	Write-Host -Object "`nFix: $Message" -ForegroundColor Green
}

function ExecuteTest (
	[string]$AssertionMessage,
	[ScriptBlock]$TestScript,
	[ScriptBlock]$FixScript
) {
	Write-Verbose "Validating that $AssertionMessage"
	
	if (-not (& $TestScript))
	{
		if ($Fix -and ($FixScript -ne $null))
		{
			& $FixScript
			if (-not (& $TestScript))
			{
				Write-TSProblem "Automatic fix for '$AssertionMessage' failed."
			}
		}
	}
}

function Test-PSInstanceMatchesOSBitness {
	Write-Debug "Checking that we're running in the correct PowerShell console for the OS"
	if (@(Get-WmiObject -Class Win32_OperatingSystem)[0].OSArchitecture -eq "64-bit") {
		if ([IntPtr]::Size -ne 8) {
			Write-TSProblem "This script must run in a 64-bit PowerShell instance when using a 64-bit operating system."
		}
	}
}

function Test-PSInstanceIsElevated {
	Write-Debug "Checking that we're running in an elevated PowerShell instance"
	$Principal = New-Object -TypeName System.Security.Principal.WindowsPrincipal -ArgumentList ([System.Security.Principal.WindowsIdentity]::GetCurrent())
	if (-not $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
		Write-TSProblem "This script must run in an elevated PowerShell instance."
	}
}