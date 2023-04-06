# PowerShell script to deploy the main.bicep template with parameter values

#Requires -Modules "Az"
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
	[string]$TemplateParameterFile = "./main.parameters-sample.jsonc"
)

# Define common parameters for the New-AzDeployment cmdlet
[hashtable]$CmdLetParameters = @{
	Location     = $Location
	TemplateFile = '.\main.bicep'
}

if ($UseParameterFile) {
	Write-Verbose "Using template parameter file"
	$CmdLetParameters.Add('TemplateParameterFile', $TemplateParameterFile)
	# Read the values from the parameters file, to use when generating the $DeploymentName value
	$ParameterFileContents = (Get-Content $TemplateParameterFile | ConvertFrom-Json).parameters
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
}
else {
	$DeploymentResult
}
