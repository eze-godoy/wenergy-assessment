# Assignment 3: Automating Infrastructure Monitoring and Alerting

## Setup

You need to install some modules for python:

```
pip install azure-mgmt-monitor azure-mgmt-compute azure-identity
```

*It's a best practice to use a virtual environment.*

## Use

To update alarms run:

```bash
python setup_azure_monitoring.py --subscription-id YSUBSCRIPTION_ID --resource-group RESOURCE_GROUP --vms vm1 vm2 vm3 --mode update
```

To list active alarms:

```bash
python setup_azure_monitoring.py --subscription-id YSUBSCRIPTION_ID --resource-group RESOURCE_GROUP --mode show
```

Some variables can be set as environment variables:

```bash
export AZURE_SUBSCRIPTION_ID=SUBSCRIPTION_ID
export AZURE_RESOURCE_GROUP=RESOURCE_GROUP

python setup_azure_monitoring.py --vms vm1 vm2 vm3 --mode update
python setup_azure_monitoring.py --mode show
```