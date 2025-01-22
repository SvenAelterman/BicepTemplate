targetScope = 'subscription'

param location string
@allowed([
  'test'
  'demo'
  'prod'
])
param environment string
param workloadName string

// Optional parameters
param tags object = {}
param sequence int = 1
param namingConvention string = '{rtype}-{workloadName}-{env}-{loc}-{seq}'
param deploymentTime string = utcNow()

// Variables
var sequenceFormatted = format('{0:00}', sequence)

var deploymentNameStructure = '${workloadName}-${environment}-{rtype}-${deploymentTime}'
// Naming structure only needs the resource type ({rtype}) replaced
var namingStructure = replace(
  replace(replace(replace(namingConvention, '{env}', environment), '{loc}', location), '{seq}', sequenceFormatted),
  '{workloadName}',
  workloadName
)

resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: replace(namingStructure, '{rtype}', 'rg')
  location: location
  tags: tags
}

module roles 'common-modules/roles.bicep' = {
  name: take(replace(deploymentNameStructure, '{rtype}', 'roles'), 64)
}

module abbreviations 'common-modules/abbreviations.bicep' = {
  name: take(replace(deploymentNameStructure, '{rtype}', 'abbrev'), 64)
  scope: workloadResourceGroup
}

// TODO: Add your deployments here

output namingStructure string = namingStructure
