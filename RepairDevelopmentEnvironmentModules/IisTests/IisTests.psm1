#requires -Version 2
$ErrorActionPreference = "Stop"

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