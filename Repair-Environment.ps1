#requires -Version 2
## ==============
## Do not modify this block.
## It should remain consistent with https://github.com/tathamoddie/Repair-Environment.ps1 to facilitate compatibility and future upgrades.
[CmdletBinding()]
param ()
$ErrorActionPreference = "Stop"
$PSScriptRoot = $MyInvocation.MyCommand.Path | Split-Path
$ModulePath = $PSScriptRoot | Join-Path -ChildPath RepairEnvironmentModules
Get-ChildItem $ModulePath -Exclude *.* | Select-Object -ExpandProperty FullName | Import-Module -Force
## ==============


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
