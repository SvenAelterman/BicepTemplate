targetScope = 'subscription'

param principalId string
param roleDefinitionId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(subscription().subscriptionId, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
  }
}
