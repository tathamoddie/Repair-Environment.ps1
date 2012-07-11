#requires -Version 2
param (
	[switch]$Confirm = $true,
	[switch]$Fix = $false,
	[switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"
if ($Verbose) { $VerbosePreference = "Continue" ; }
$PSScriptRoot = $MyInvocation.MyCommand.Path | Split-Path
$ModulePath = $PSScriptRoot | Join-Path -ChildPath RepairDevelopmentEnvironmentModules

Import-Module $ModulePath\TestHarness
Import-Module $ModulePath\IisTests
Import-Module $ModulePath\SecurityTests

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
