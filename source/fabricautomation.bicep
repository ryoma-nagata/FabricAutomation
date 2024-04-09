@description('''
ロジックアプリのロケーション。既定でリソースグループと同じリージョンになります
''')
param location string = resourceGroup().location

@description('''
ロジックアプリの名称
''')
param logicAppsName string 

@description('''
実施したいFabric容量操作
''')
@allowed([
  'suspend'
  'resume'
  'scaling'
])
param action string
@description('''
対象のFabric容量名
''')
param capacityName string = 'demofabric'
@description('''
対象のFabricが存在するリソースグループ名
''')
param resourceGroupName string 

@description('''
対象のFabricが存在するサブスクリプションID
''')
param subscriptionId string 
@description('''
actionがscalingの場合の変更後SKU.
''')
@allowed([
  'F2'
  'F4'
  'F8'
  'F16'
  'F32'
  'F64'
  'F128'
  'F256'
  'F512'
  'F1024'
  'F2048'
])
param sku string = 'F2'

resource logicApps 'Microsoft.Logic/workflows@2017-07-01' = {
  name: logicAppsName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        Action: {
          defaultValue: action
          type: 'String'
        }
        CapacityName: {
          defaultValue: capacityName
          type: 'String'
        }
        ResourceGroupName: {
          defaultValue: resourceGroupName
          type: 'String'
        }
        SubscriptionId: {
          defaultValue: subscriptionId
          type: 'String'
        }
        sku: {
          defaultValue: sku
          type: 'String'
        }
      }
      triggers: {
        '繰り返し': {
          recurrence: {
            frequency: 'Day'
            interval: 1
            schedule: {
              hours: [
                '1'
              ]
            }
            timeZone: 'Tokyo Standard Time'
          }
          evaluatedRecurrence: {
            frequency: 'Day'
            interval: 1
            schedule: {
              hours: [
                '1'
              ]
            }
            timeZone: 'Tokyo Standard Time'
          }
          type: 'Recurrence'
        }
      }
      actions: {
        'Fabric_状態取得': {
          runAfter: {}
          type: 'Http'
          inputs: {
            authentication: {
              type: 'ManagedServiceIdentity'
            }
            method: 'GET'
            uri: 'https://management.azure.com/subscriptions/@{parameters(\'SubscriptionId\')}/resourceGroups/@{parameters(\'ResourceGroupName\')}/providers/Microsoft.Fabric/capacities/demofabric?api-version=2022-07-01-preview'
          }
        }
        'Fabric_状態解析': {
          runAfter: {
            'Fabric_状態取得': [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Fabric_状態取得\')'
            schema: {
              properties: {
                id: {
                  type: 'string'
                }
                location: {
                  type: 'string'
                }
                name: {
                  type: 'string'
                }
                properties: {
                  properties: {
                    administration: {
                      properties: {
                        members: {
                          items: {
                            type: 'string'
                          }
                          type: 'array'
                        }
                      }
                      type: 'object'
                    }
                    provisioningState: {
                      type: 'string'
                    }
                    state: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
                sku: {
                  properties: {
                    name: {
                      type: 'string'
                    }
                    tier: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
                tags: {
                  properties: {}
                  type: 'object'
                }
                type: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
        'actionパラメータ分岐': {
          runAfter: {
            'Fabric_状態解析': [
              'Succeeded'
            ]
          }
          cases: {
            resume: {
              case: 'resume'
              actions: {
                '停止済み': {
                  actions: {
                    'Fabric_開始': {
                      runAfter: {}
                      type: 'Http'
                      inputs: {
                        authentication: {
                          type: 'ManagedServiceIdentity'
                        }
                        method: 'POST'
                        uri: 'https://management.azure.com/subscriptions/@{parameters(\'SubscriptionId\')}/resourceGroups/@{parameters(\'ResourceGroupName\')}/providers/Microsoft.Fabric/capacities/@{parameters(\'CapacityName\')}/resume?api-version=2022-07-01-preview'
                      }
                    }
                  }
                  runAfter: {}
                  expression: {
                    and: [
                      {
                        equals: [
                          '@body(\'Fabric_状態解析\')?[\'properties\']?[\'state\']'
                          'Paused'
                        ]
                      }
                    ]
                  }
                  type: 'If'
                }
              }
            }
            scaling: {
              case: 'scaling'
              actions: {
                'SKU変更なし': {
                  actions: {}
                  runAfter: {}
                  else: {
                    actions: {
                      'Fabric_SKU変更': {
                        runAfter: {}
                        type: 'Http'
                        inputs: {
                          authentication: {
                            type: 'ManagedServiceIdentity'
                          }
                          body: {
                            sku: {
                              name: '@{parameters(\'sku\')}'
                              tier: 'Fabric'
                            }
                          }
                          method: 'PATCH'
                          uri: 'https://management.azure.com/subscriptions/@{parameters(\'SubscriptionId\')}/resourceGroups/@{parameters(\'ResourceGroupName\')}/providers/Microsoft.Fabric/capacities/\n@{parameters(\'CapacityName\')}?api-version=2022-07-01-preview'
                        }
                      }
                    }
                  }
                  expression: {
                    and: [
                      {
                        equals: [
                          '@body(\'Fabric_状態解析\')?[\'sku\']?[\'name\']'
                          '@parameters(\'sku\')'
                        ]
                      }
                    ]
                  }
                  type: 'If'
                }
              }
            }
            suspend: {
              case: 'suspend'
              actions: {
                '開始済み': {
                  actions: {
                    'Fabric_停止': {
                      runAfter: {}
                      type: 'Http'
                      inputs: {
                        authentication: {
                          type: 'ManagedServiceIdentity'
                        }
                        method: 'POST'
                        uri: 'https://management.azure.com/subscriptions/@{parameters(\'SubscriptionId\')}/resourceGroups/@{parameters(\'ResourceGroupName\')}/providers/Microsoft.Fabric/capacities/@{parameters(\'CapacityName\')}/@{parameters(\'Action\')}?api-version=2022-07-01-preview'
                      }
                    }
                  }
                  runAfter: {}
                  expression: {
                    and: [
                      {
                        equals: [
                          '@body(\'Fabric_状態解析\')?[\'properties\']?[\'state\']'
                          'Active'
                        ]
                      }
                    ]
                  }
                  type: 'If'
                }
              }
            }
          }
          default: {
            actions: {
              '終了': {
                runAfter: {}
                type: 'Terminate'
                inputs: {
                  runStatus: 'Succeeded'
                }
              }
            }
          }
          expression: '@parameters(\'Action\')'
          type: 'Switch'
        }
      }
      outputs: {}
    }
    parameters: {}
  }
}
