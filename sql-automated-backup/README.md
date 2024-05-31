# Assignment 4: Automated Backup and Restore for Azure SQL Database

## Setup

You need to install some modules for python:

```
pip install azure-cli azure-mgmt-sql azure-identity azure-storage-blob
```

*It's a best practice to use a virtual environment.*

## Use

Backup Database:

```bash
python manage_sql_backup.py --subscription-id YOUR_SUBSCRIPTION_ID --resource-group YOUR_RESOURCE_GROUP --server-name YOUR_SERVER_NAME --database-name YOUR_DATABASE_NAME --storage-account YOUR_STORAGE_ACCOUNT --container-name YOUR_CONTAINER_NAME --mode backup
```

Restore Database:

```bash
python manage_sql_backup.py --subscription-id YOUR_SUBSCRIPTION_ID --resource-group YOUR_RESOURCE_GROUP --server-name YOUR_SERVER_NAME --database-name YOUR_DATABASE_NAME --storage-account YOUR_STORAGE_ACCOUNT --container-name YOUR_CONTAINER_NAME --mode restore --backup-name YOUR_BACKUP_NAME.bacpac
```

List Backups:

```bash
python manage_sql_backup.py --subscription-id YOUR_SUBSCRIPTION_ID --resource-group YOUR_RESOURCE_GROUP --server-name YOUR_SERVER_NAME --database-name YOUR_DATABASE_NAME --storage-account YOUR_STORAGE_ACCOUNT --container-name YOUR_CONTAINER_NAME --mode list
```

## Consideration

For production ready script it would be ideal to add better error handling and notifications.