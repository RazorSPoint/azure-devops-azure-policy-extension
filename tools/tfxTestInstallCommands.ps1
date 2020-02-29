# if not logged in, run the login
tfx login -u https://dev.azure.com/razorspoint-test

# upload the deploy azure policy task
tfx build tasks upload --task-path ./src/AzurePolicy/AzurePolicyV1

# upload the deploy azure initiative task
tfx build tasks upload --task-path ./src/AzureInitiative/AzureInitiativeV1

# delete the task
tfx build tasks delete --task-id ef6e39d1-dbac-47e0-8c6b-f5735aaa4096

tfx build tasks delete --task-id 28825f8c-9d9c-4561-8d2a-429aa4ca7271

 #### for publishing manually to test tenant  
 tfx extension publish --publisher razorspoint --share-with razorspoint-trashdummy --output-path ./bin --rev-version --token #PatToken#