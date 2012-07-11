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

Import-Module -Force -Name $ModulePath\TestHarness
Import-Module -Force -Name $ModulePath\IisTests
Import-Module -Force -Name $ModulePath\SecurityTests

Test-PSInstanceMatchesOSBitness
Test-PSInstanceIsElevated

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
