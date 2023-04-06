# BicepTemplate

Template repo for creating a new Bicep deployment.

## Usage

### main.bicep

This is the template that will be deployed. You should add modules here.

### deploy.ps1

This PowerShell script will deploy your main.bicep template.

`./deploy.ps1 -UseParameterFile`

-- OR --

`./deploy.ps1 -UsePSParameters -Environment 'test' ...`

### common-modules

The modules in this folder are modules that contain re-usable outputs.

### modules

You should create your own modules folder and reference those modules from main.bicep or other modules.

## Parameters

Here are the common parameters defined by the template main.bicep:

- **location**: The Azure region to target for deployments.
- **environment**: An environment value, such as "dev."
- **workloadName**: The name of the workload to be deployed. This will be used to name deployments and to complete the naming convention.
- **sequence** (optional, defaults to `1`)
- **tags** (optional, defaults to none)
- **namingConvention** (optional, defaults to `{rtype}-{workloadName}-{env}-{loc}-{seq}`): the structure of the Azure resources names. Use placeholders as follows:
  - **{rtype}**: The resource type. Your main.bicep should replace {rtype} with the recommended Azure resource type abbreviation as found at <https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations>.
  - **{workloadName}**: Replaced with the value of the `workloadName` parameter.
  - **{env}**: Replaced with the value of the `environment` parameter.
  - **{loc}**: Replaced with the value of the `location` parameter.
  - **{seq}**: Replaced with the string value of the sequence parameter, always formatted as two digits.

When not using a template parameter file, these parameters are passed to the deployment from the PowerShell script using a `$TemplateParameters` PowerShell object, which uses parameter splatting for increased resilience.
