#requires -Version 2

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
