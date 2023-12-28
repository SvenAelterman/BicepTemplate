param kvName string
param principalId string
param roleDefinitionId string
param secretName string

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' existing = {
  name: secretName
  parent: kv
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(secret.id, principalId, roleDefinitionId)
  scope: secret
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
  }
}
