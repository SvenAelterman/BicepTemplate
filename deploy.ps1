<#
.SYNOPSIS
Deploy the main.bicep template with parameter values or a parameter file.

.DESCRIPTION
Performs the Bicep deployment specified in the Bicep file using the New-AzDeployment cmdlet.

.EXAMPLE
.\deploy.ps1 -Location 'eastus2' -Environment 'test' -WorkloadName 'biceptemplate2' -Sequence 1 -NamingConvention '{rtype}-{workloadName}-{env}-{loc}-{seq}'

.EXAMPLE
.\deploy.ps1 -UseParameterFile -TemplateParameterFile './main.sample.bicepparam' -Verbose -DeleteJsonParameterFileAfterDeployment
#>

#Requires -Modules "Az.Resources"
#Requires -PSEdition Core

# Use these parameters to customize the deployment instead of modifying the default parameter values
[CmdletBinding()]
Param(
	[ValidateSet('eastus2', 'eastus')]
	[Parameter()]
	[string]$Location = 'eastus',
	# Using PS function parameters
	[Parameter(ParameterSetName = 'NoParamFile')]
	[switch]$UsePSParameters,
	[ValidateSet('test', 'demo', 'prod')]
	[Parameter(ParameterSetName = 'NoParamFile', Mandatory)]
	[string]$Environment,
	# The Mandatory keyword here allows differentiation between the parameter sets
	[Parameter(ParameterSetName = 'NoParamFile', Mandatory)]
	[string]$WorkloadName = 'biceptemplate2',
	[Parameter(ParameterSetName = 'NoParamFile', Mandatory)]
	[int]$Sequence,
	[Parameter(ParameterSetName = 'NoParamFile')]
	[string]$NamingConvention = "{rtype}-{workloadName}-{env}-{loc}-{seq}",
	# Using parameters file
	[Parameter(ParameterSetName = 'ParamFile')]
	[switch]$UseParameterFile,
	[Parameter(ParameterSetName = 'ParamFile', Position = 1)]
	[string]$TemplateParameterFile = "./main.sample.bicepparam",
	[Parameter()]
	[bool]$DeleteJsonParameterFileAfterDeployment = $true
)

# Define common parameters for the New-AzDeployment cmdlet
[hashtable]$CmdLetParameters = @{
	Location     = $Location
	TemplateFile = '.\main.bicep'
}

if ($UseParameterFile) {
	Write-Verbose "Using template parameter file '$TemplateParameterFile'."
	$CmdLetParameters.Add('TemplateParameterFile', $TemplateParameterFile)
	[string]$TemplateParameterJsonFile = [System.IO.Path]::ChangeExtension($TemplateParameterFile, 'json')
	bicep build-params $TemplateParameterFile --outfile $TemplateParameterJsonFile

	# Read the values from the parameters file, to use when generating the $DeploymentName value
	$ParameterFileContents = (Get-Content $TemplateParameterJsonFile | ConvertFrom-Json).parameters
	$WorkloadName = $ParameterFileContents.workloadName.value
	$Environment = $ParameterFileContents.environment.value
}
else {
	Write-Verbose "Creating template parameter object"
	# Create a template parameter object based on the PS parameters
	$TemplateParameters = @{
		# REQUIRED
		location         = $Location
		environment      = $Environment
		workloadName     = $WorkloadName
	
		# OPTIONAL
		sequence         = $Sequence
		namingConvention = $NamingConvention
		tags             = @{
			'date-created' = (Get-Date -Format 'yyyy-MM-dd')
			purpose        = $Environment
			lifetime       = 'short'
		}
	}

	$CmdLetParameters.Add('TemplateParameterObject', $TemplateParameters)
}

# Generate a unique name for the deployment
[string]$DeploymentName = "$WorkloadName-$Environment-$(Get-Date -Format 'yyyyMMddThhmmssZ' -AsUTC)"
$CmdLetParameters.Add('Name', $DeploymentName)

# Execute the deployment
$DeploymentResult = New-AzDeployment @CmdLetParameters

# Evaluate the deployment results
if ($DeploymentResult.ProvisioningState -eq 'Succeeded') {
	Write-Host "🔥 Deployment succeeded."

	if ($DeleteJsonParameterFileAfterDeployment) {
		Write-Verbose "Deleting template parameter JSON file '$TemplateParameterJsonFile'."
		Remove-Item -Path $TemplateParameterJsonFile -Force
	}
	
	$DeploymentResult.Outputs | Format-Table -Property @{Name = 'Output Name'; Expression = { $_.Key } }, @{Name = 'Value'; Expression = { $_.Value.Value } }
}
else {
	$DeploymentResult
}
