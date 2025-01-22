using 'main.bicep'

param location = 'eastus'

param environment = 'test'

param workloadName = 'biceptemplate'

param sequence = 1

param tags = {
  lifetime: 'short'
  purpose: 'test'
}
