import os
import argparse
import logging
from azure.identity import DefaultAzureCredential
from azure.mgmt.sql import SqlManagementClient
from azure.storage.blob import BlobServiceClient
from azure.cli.core import get_default_cli


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

#region arguments
parser = argparse.ArgumentParser(description='Manage Azure SQL Database backup and restore.')
parser.add_argument('--subscription-id', type=str, required=True, help='Azure subscription ID')
parser.add_argument('--resource-group', type=str, required=True, help='Azure resource group name')
parser.add_argument('--server-name', type=str, required=True, help='Azure SQL server name')
parser.add_argument('--database-name', type=str, required=True, help='Azure SQL database name')
parser.add_argument('--storage-account', type=str, required=True, help='Azure Storage account name')
parser.add_argument('--container-name', type=str, required=True, help='Azure Storage container name')
parser.add_argument('--mode', choices=['backup', 'restore', 'list'], required=True, help='Mode to either backup, restore or list backups')
parser.add_argument('--backup-name', type=str, help='Name of the backup to restore')
args = parser.parse_args()
#endregion

#region login
subscription_id = args.subscription_id
resource_group_name = args.resource_group
server_name = args.server_name
database_name = args.database_name
storage_account_name = args.storage_account
container_name = args.container_name
mode = args.mode
backup_name = args.backup_name

credential = DefaultAzureCredential()

sql_client = SqlManagementClient(credential, subscription_id)
#endregion

def az_cli(command):
    get_default_cli().invoke(command.split())

def backup_database():
    logger.info("Starting backup process...")
    backup_name = f"{database_name}-backup-{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}.bacpac"
    storage_uri = f"https://{storage_account_name}.blob.core.windows.net/{container_name}/{backup_name}"
    
    # Export database to BACPAC file in the storage account
    az_cli(f"az sql db export --admin-user <admin-username> --admin-password <admin-password> "
           f"--server {server_name} --name {database_name} --storage-uri {storage_uri} "
           f"--resource-group {resource_group_name} --subscription {subscription_id}")
    
    logger.info(f"Backup {backup_name} created successfully and stored at {storage_uri}")

def restore_database():
    if not backup_name:
        logger.error("Backup name is required for restore process.")
        return

    logger.info("Starting restore process...")
    storage_uri = f"https://{storage_account_name}.blob.core.windows.net/{container_name}/{backup_name}"
    
    az_cli(f"az sql db import --admin-user <admin-username> --admin-password <admin-password> "
           f"--server {server_name} --name {database_name} --storage-uri {storage_uri} "
           f"--resource-group {resource_group_name} --subscription {subscription_id}")
    
    logger.info(f"Database {database_name} restored successfully from {backup_name}")

def list_backups():
    logger.info("Listing all backups...")
    blob_service_client = BlobServiceClient(account_url=f"https://{storage_account_name}.blob.core.windows.net/", credential=credential)
    container_client = blob_service_client.get_container_client(container_name)
    
    blobs = container_client.list_blobs()
    for blob in blobs:
        logger.info(f"Backup: {blob.name}, Size: {blob.size}, Last Modified: {blob.last_modified}")

#region main
if mode == 'backup':
    backup_database()
elif mode == 'restore':
    restore_database()
elif mode == 'list':
    list_backups()

#endregion