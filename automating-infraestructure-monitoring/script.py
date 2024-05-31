import os
import argparse
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.monitor import MonitorManagementClient
from azure.mgmt.monitor.models import (
    MetricAlertResource,
    MetricAlertCriteria,
    ThresholdRuleCondition,
    RuleMetricDataSource,
    MetricAlertAction,
    TimeAggregationOperator,
    MetricAlertCriteriaOperator
)

#region arguments
parser = argparse.ArgumentParser(description='Manage Azure VM monitoring.')
parser.add_argument('--subscription-id', type=str, help='Azure subscription ID')
parser.add_argument('--resource-group', type=str, help='Azure resource group name')
parser.add_argument('--vms', nargs='+', help='List of VM names')
parser.add_argument('--mode', choices=['update', 'show'], required=True, help='Mode to either update alarms or show current alarms')
args = parser.parse_args()
#endregion

#region Azure Auth
subscription_id = args.subscription_id or os.getenv('AZURE_SUBSCRIPTION_ID')
resource_group_name = args.resource_group or os.getenv('AZURE_RESOURCE_GROUP')

if not subscription_id or not resource_group_name:
    print("Subscription ID and Resource Group are required.")
    exit(1)

credential = DefaultAzureCredential()

compute_client = ComputeManagementClient(credential, subscription_id)

monitor_client = MonitorManagementClient(credential, subscription_id)
#endregion

#region create/update
def create_or_update_metric_alert(vm_id, vm_name, metric_name, operator, threshold, time_aggregation, alert_name, action_group_id):
    metric_alert = MetricAlertResource(
        location='global',
        description=f'{metric_name} alert for {vm_name}',
        severity=2,
        enabled=True,
        scopes=[vm_id],
        evaluation_frequency='PT1M',
        window_size='PT5M',
        criteria=MetricAlertCriteria(
            all_of=[
                ThresholdRuleCondition(
                    data_source=RuleMetricDataSource(
                        metric_name=metric_name,
                        resource_uri=vm_id
                    ),
                    operator=operator,
                    threshold=threshold,
                    time_aggregation=time_aggregation
                )
            ]
        ),
        actions=[
            MetricAlertAction(
                action_group_id=action_group_id,
                web_hook_properties={}
            )
        ]
    )
    monitor_client.metric_alerts.create_or_update(resource_group_name, alert_name, metric_alert)
#endregion

#region list
def show_active_alerts():
    alerts = monitor_client.metric_alerts.list_by_subscription()
    for alert in alerts:
        print(f"Alert: {alert.name}")
        print(f"  Status: {alert.enabled}")
        print(f"  Criteria: {alert.criteria}")
#endregion

if args.mode == 'update':
    if not args.vms:
        print("At least one VM name is required for update mode.")
        exit(1)

    vm_names = args.vms

    for vm_name in vm_names:
        vm = compute_client.virtual_machines.get(resource_group_name, vm_name)
        vm_id = vm.id

        create_or_update_metric_alert(
            vm_id, vm_name, 'Percentage CPU',
            MetricAlertCriteriaOperator.GREATER_THAN, 80,
            TimeAggregationOperator.AVERAGE, f'cpu_metric_alert_{vm_name}',
            '/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/microsoft.insights/actionGroups/{action_group_name}'
        )

        create_or_update_metric_alert(
            vm_id, vm_name, 'Available Memory Bytes',
            MetricAlertCriteriaOperator.LESS_THAN, 209715200,
            TimeAggregationOperator.AVERAGE, f'memory_metric_alert_{vm_name}',
            '/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/microsoft.insights/actionGroups/{action_group_name}'
        )
        
elif args.mode == 'show':
    show_active_alerts()
