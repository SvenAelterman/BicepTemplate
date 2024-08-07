<#
.SYNOPSIS
	PowerShell script to test the createValidAzResourceName Bicep module.
#>

#Requires -Modules "Az"
#Requires -PSEdition Core

# Use these parameters to customize the deployment instead of modifying the default parameter values
[CmdletBinding()]
Param(
	[ValidateSet('eastus2', 'eastus')]
	[string]$Location = 'eastus2',
	# The environment descriptor
	[ValidateSet('test', 'demo', 'prod')]
	[string]$Environment = 'test',
	[string]$WorkloadName = 'myworkload',
	[int]$Sequence = 1,
	[string]$NamingConvention = "{rtype}-{workloadName}-{env}-{loc}-{seq}",
	[ValidateSet('cr', 'st', 'ci', 'pg', 'kv')]
	[string]$ResourceType = 'st',
	[string]$ExpectedShortName = 'stmyworkloadteus21',
	[int]$AddRandomChars = 0
)

function Confirm-DeploymentResult {
	[CmdletBinding()]
	param (
		[Parameter(Position = 1)]
		$DeploymentResult,
		[Parameter(Position = 2)]
		[string]$ExpectedShortName
	)

	if ($DeploymentResult.ProvisioningState -eq 'Succeeded') {
		Write-Verbose "Deployment success"

		[string]$ShortNameOutput = $DeploymentResult.Outputs.validName.Value
	
		if ($ShortNameOutput -Like $ExpectedShortName) {
			Write-Host "✓ Short name '$ShortNameOutput' matches expected value! 🔥"
			return $true
		}
		else {
			Write-Error "✕ Names do not match: '$ExpectedShortName' (expected) != '$ShortNameOutput' (output) 🙁"
		}
	}
	else {
		Write-Error "🙁 Deployment Error"
	}

	return $false
}

# ARRANGE
$TemplateParameters = @{
	# REQUIRED
	location         = $Location
	environment      = $Environment
	workloadName     = $WorkloadName
	resourceType     = $ResourceType

	# OPTIONAL
	sequence         = $Sequence
	namingConvention = $NamingConvention
	addRandomChars   = $AddRandomChars
}

$TemplateFile = '.\common-modules\createValidAzResourceName.bicep'

# ACT
$DeploymentResult = New-AzDeployment -Location $Location -Name "$WorkloadName-$Environment-$(Get-Date -Format 'yyyyMMddThhmmssZ' -AsUTC)" `
	-TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameters

# ASSERT
[bool]$Success = Confirm-DeploymentResult $DeploymentResult $ExpectedShortName

### ADDITIONAL MANUAL TESTS ###

# ARRANGE
$TemplateParameters.addRandomChars = 4
$ExpectedShortName = 'stmyworkload????teus21'

# ACT
$DeploymentResult = New-AzDeployment -Location $Location -Name "$WorkloadName-$Environment-$(Get-Date -Format 'yyyyMMddThhmmssZ' -AsUTC)" `
	-TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameters

# ASSERT
[bool]$Success = Confirm-DeploymentResult $DeploymentResult $ExpectedShortName

# ARRANGE
$TemplateParameters.addRandomChars = 0
$TemplateParameters.resourceType = 'pg'
$ExpectedShortName = "pg-myworkload-test-eastus2-01"

# ACT
$DeploymentResult = New-AzDeployment -Location $Location -Name "$WorkloadName-$Environment-$(Get-Date -Format 'yyyyMMddThhmmssZ' -AsUTC)" `
	-TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameters

# ASSERT
$Success = $Success -And (Confirm-DeploymentResult $DeploymentResult $ExpectedShortName)

# ARRANGE
$TemplateParameters.addRandomChars = 4
$TemplateParameters.workloadName = 'myreallylongworkloadname-thatwillbeshortenedforsure'
$TemplateParameters.resourceType = 'pg'
$ExpectedShortName = "pg-myreallylongworkloadname-thatwillbeshortenedfor????-t-eus2-1"

# ACT
$DeploymentResult = New-AzDeployment -Location $Location -Name "$WorkloadName-$Environment-$(Get-Date -Format 'yyyyMMddThhmmssZ' -AsUTC)" `
	-TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameters

# ASSERT
$Success = (Confirm-DeploymentResult $DeploymentResult $ExpectedShortName) -And $Success

# ARRANGE
$TemplateParameters.useRemoveVowelStrategy = $true
$ExpectedShortName = "pg-myrllylngwrkldnm-thtwllbshrtndfrsr????-t-eus2-1"

# ACT
$DeploymentResult = New-AzDeployment -Location $Location -Name "$WorkloadName-$Environment-$(Get-Date -Format 'yyyyMMddThhmmssZ' -AsUTC)" `
	-TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameters

# ASSERT
$Success = (Confirm-DeploymentResult $DeploymentResult $ExpectedShortName) -And $Success

# ARRANGE
$TemplateParameters.useRemoveVowelStrategy = $false
$TemplateParameters.addRandomChars = 2
$TemplateParameters.workloadName = 'researchhub-core'
$TemplateParameters.resourceType = 'st'
$ExpectedShortName = "stresearchhubcor??teus21"

# ACT
$DeploymentResult = New-AzDeployment -Location $Location -Name "$WorkloadName-$Environment-$(Get-Date -Format 'yyyyMMddThhmmssZ' -AsUTC)" `
	-TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameters

# ASSERT
$Success = (Confirm-DeploymentResult $DeploymentResult $ExpectedShortName) -And $Success

# ARRANGE
$TemplateParameters.namingConvention = '{workloadName}-{env}-{rtype}-{loc}-{seq}'
$ExpectedShortName = "researchhubcor??tsteus21"

# ACT
$DeploymentResult = New-AzDeployment -Location $Location -Name "$WorkloadName-$Environment-$(Get-Date -Format 'yyyyMMddThhmmssZ' -AsUTC)" `
	-TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameters

# ASSERT
$Success = (Confirm-DeploymentResult $DeploymentResult $ExpectedShortName) -And $Success

return $Success