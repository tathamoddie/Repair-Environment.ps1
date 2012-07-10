#requires -Version 2
param (
	[switch]$Confirm = $true,
	[switch]$Fix = $false,
	[switch]$Verbose = $false
)

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

function Test-IisBindingExists (
	$AssertionMessage,
	$Port,
	$Hostname,
	$ExpectedSiteBinding
) {
	ExecuteTest `
		-AssertionMessage $AssertionMessage `
		-TestScript {
		
			$Binding = ":$($Port):$($Hostname)"
		
			$ActualSite = Get-WebSite |
				Where-Object {
					@($_.Bindings.Collection | 
						Select-Object -ExpandProperty BindingInformation |
						Where-Object { $_ -like "*$Binding" }).Length -gt 0
				}
			$ExpectedSite = Get-WebSite |
				Where-Object {
					@($_.Bindings.Collection | 
						Select-Object -ExpandProperty BindingInformation |
						Where-Object { $_ -like "*$ExpectedSiteBinding" }).Length -gt 0
				}
			
			if ($ExpectedSite -eq $null) {
				# we have bigger problems
				Write-Verbose "The $ExpectedSiteBinding site was not found so the test could not be performed."
				return $true
			}
			
			if ($ActualSite -eq $null) {
				Write-TSProblem "IIS site with binding $Binding not found. Should be bound to IIS site $($ExpectedSite.Name)."
				return $false
			}
			
			return $true
		} `
		-FixScript {
			$ExpectedSite = Get-WebSite |
				Where-Object {
					@($_.Bindings.Collection | 
						Select-Object -ExpandProperty BindingInformation |
						Where-Object { $_ -like "*$ExpectedSiteBinding" }).Length -gt 0
				}
		
			Write-TSFix "Adding :$Port:$Hostname binding to IIS site $($ExpectedSite.Name)."
			New-WebBinding -Name $ExpectedSite.Name -IPAddress "*" -Port $Port -HostHeader $Hostname
		}
}

function Test-IisBindingIsToCorrectSite (
	$AssertionMessage,
	$Port,
	$Hostname,
	$ExpectedSiteBinding
) {
	ExecuteTest `
		-AssertionMessage $AssertionMessage `
		-TestScript {
			
			$Binding = ":$($Port):$($Hostname)"
		
			$ActualSite = Get-WebSite |
				Where-Object {
					@($_.Bindings.Collection | 
						Select-Object -ExpandProperty BindingInformation |
						Where-Object { $_ -like "*$Binding" }).Length -gt 0
				}
			$ExpectedSite = Get-WebSite |
				Where-Object {
					@($_.Bindings.Collection | 
						Select-Object -ExpandProperty BindingInformation |
						Where-Object { $_ -like "*$ExpectedSiteBinding" }).Length -gt 0
				}
			
			if ($ActualSite -eq $null -or
				$ExpectedSite -eq $null) {
				# we have bigger problems
				Write-Verbose "Neither the $Binding or $ExpectedSiteBinding sites were found so the test could not be performed."
				return $true
			}
			
			if ($ActualSite.ID -ne $ExpectedSite.ID) {
				Write-TSProblem "The $Binding binding does not belong to IIS site $($ExpectedSite.Name)."
				return $false
			}
			
			return $true
		} `
		-FixScript {
			
			$Binding = ":$($Port):$($Hostname)"
		
			$ExpectedSite = Get-WebSite |
				Where-Object {
					@($_.Bindings.Collection | 
						Select-Object -ExpandProperty BindingInformation |
						Where-Object { $_ -like "*$ExpectedSiteBinding" }).Length -gt 0
				}
		
			Write-TSFix "Removing erroneous $Binding binding"
			Remove-WebBinding -Port $Port -HostHeader $Hostname
			
			Write-TSFix "Adding :$Port:$Hostname binding to IIS site $($ExpectedSite.Name)."
			New-WebBinding -Name $ExpectedSite.Name -IPAddress "*" -Port $Port -HostHeader $Hostname
		}
}

$ErrorActionPreference = "Stop"
if ($Verbose) { $VerbosePreference = "Continue" ; }

$PSScriptFilePath = (get-item $MyInvocation.MyCommand.Path).FullName
$PSScriptRoot = Split-Path -Path $PSScriptFilePath -Parent

Write-Debug "Checking that we're running in the correct PowerShell console for the OS"
if (@(Get-WmiObject -Class Win32_OperatingSystem)[0].OSArchitecture -eq "64-bit") {
	if ([IntPtr]::Size -ne 8) {
		Write-TSProblem "This script must run in a 64-bit PowerShell instance when using a 64-bit operating system."
	}
}

Write-Debug "Checking that we're running in an elevated PowerShell instance"
$Principal = New-Object -TypeName System.Security.Principal.WindowsPrincipal -ArgumentList ([System.Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
	Write-TSProblem "This script must run in an elevated PowerShell instance."
}

Test-BackConnectionHostNames "www.site.localtest.me"
Test-BackConnectionHostNames "site.localtest.me"

Write-TSManualStep "Ensure the ASP.NET 2.0 ISAPI filter is enabled"

foreach ($resourceDomain in @("res0.site.localtest.me", "res1.site.localtest.me", "res2.site.localtest.me", "res3.site.localtest.me"))
{
	Test-IisBindingExists `
		-AssertionMessage ":80:$resourceDomain binding exists in IIS" `
		-Port 80 `
		-Hostname $resourceDomain `
		-ExpectedSiteBinding "*:80:www.site.localtest.me"
	
	Test-IisBindingIsToCorrectSite `
		-AssertionMessage "$resourceDomain bound to correct IIS site" `
		-Port 80 `
		-Hostname $resourceDomain `
		-ExpectedSiteBinding "*:80:www.site.localtest.me"
}

Write-TSManualStep "Ensure that SQL has the TCP/IP protocol enabled."
