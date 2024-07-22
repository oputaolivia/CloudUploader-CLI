#!/bin/bash

echo 'Hello'
# Upload file
upload_file(){
    # Login User
    login_user

    read -p "Enter container name: " container
    read -p "Enter Storage account name: " storageAccount
    read -p "Enter Resource Group name: " resourceGroup

    check_container
    accountKey = $(storage_account_keys) 
    az storage blob upload-batch --pattern "container_size_sample_file_*.txt" --source $filePath --destination $container --account-key $accountKey --account-name $storageAccount
}

# Check if container exists
check_container(){
    echo "Checking if Container exists ..."
    if [ $(az storage container exists --name $container --account-name $storageAccount --account-key $accountKey) = true ]; then 
        echo "The container $container exists "
    else
        create_container
    fi
}

# Create Container
create_container(){
    check_storage_account
    az storage container create --account-name $storageAccount --account-key $accountKey --name $container
}

# Get Storage Account Keys
storage_account_keys(){
    accountKey=$(az storage account keys list --resource-group $resourceGroup --account-name $storageAccount --query "[0].value" -o tsv)
    echo "Storage Account Key is: $accountKey"
}

# Check storage account
check_storage_account(){
    echo "Checking if Storage Account exists ..."
    if [ $(az storage account check-name --name $storageAccount) = true ]; then
        echo "Storage account exists."
    else
        echo "Storage Account does not exist"
        create_storage_account
    fi
}

# Create Storage Account
create_storage_account(){
    check_resource_group
    az storage account create --name $storageAccount --location "$selected_region" --resource-group $resourceGroup --sku Standard_LRS --encryption-services blob

}

# Check if resource group already exists.
check_resource_group () {
    echo "Checking if resource gorup exists ..."

    if [ $(az group exists --name $resourceGroup) = true ]; then 
        echo "Resource Group Exists"
    else
        echo "Resource Group does not exist"
        print_out_regions
        check_region
        create_resource_group "$resourceGroup"
    fi
}

# Print out 5 recommended regions
print_out_regions() {
    regions_array=($( az account list-locations --query "[?metadata.regionCategory=='Recommended'].{Name:name}" -o tsv | head -n 5))
    for i in "${regions_array[@]}"
    do
       echo "$i"
    done
}

# Select a region
check_region() {
    print_out_regions
    read -p "Enter your region: " selected_region
}

# Create the resource group
create_resource_group () {
    echo "Creating resource group: $resourceGroup in $selected_region"
    az group create -g $resourceGroup -l $selected_region | grep provisioningState
}


setup() { 
    # Install az cli
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    # Login
    az login --use-device-code
    echo "You're logged in."
}
login_user(){
    # Login
    az login --use-device-code
    echo "You're logged in."
}
#List all resource groups
list_resource_groups() {
    az group list -o table
}


echo "Welcome to Cloud Uploader"

# setup
upload_file