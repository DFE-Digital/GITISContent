# Technical
Securely connecting Google Drive to Microsoft Azure, and providing a bespoke domain

![Overview](./asset.png)

## Environments
There are two main environments for the copy process, development and production.
### Development
This consists of just the Apps Script and the Azure Storage account and is mainly to test any changes to the Apps Script prior to deployment.
### Production
This is the main environment and is currently the only place where all the components are setup and linked together. As well as the Apps Script and Azure Storage account the environment additionally consists of the CDN and custom domain.

## Google
### Google Drive
The [Shared drive](https://drive.google.com/drive/folders/0AJ6YEVtSfOQVUk9PVA) has been created by the [Digital Tools Support](https://sites.google.com/digital.education.gov.uk/digitaltools/home) team and **Manager** access has been granted to a number of team members.

Team members who need to manage assets can be granted **Contributor** access by any of the managers.

### Google Scripts
Periodically a [Google Script](https://github.com/DFE-Digital/GITISContent/tree/main/Google) needs to run. This will transfer the assets from the [Shared drive](https://drive.google.com/drive/folders/0AJ6YEVtSfOQVUk9PVA) to an Azure Storage account.

The script needs to have an [Azure SAS Key](https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview) embedded into it, which gives access to the Azure Storage account. Since this key is sensitive, it is stored in Azure Key Vault and injected into the script at deployment time.


## Azure
### Storage Accounts
Within the relevant Azure subscription a [Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview?toc=/azure/storage/blobs/toc.json) `SubIdEnvIdgitiscontent` has been created.

This storage account has a container called "**content**" which has been set as a [Static Website](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website).

This can be setup using the ARM template by executing the make target `make <environment> storage_create` (where environment is either `development` or `production`).

A [Shared Access Signature](https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview) has been created for this [Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview?toc=/azure/storage/blobs/toc.json). A SAS can be generated using the `make <environment> storage_sas_create` target. On Linux the `date` command option `-v +365d` is replaced by `-d "+365 days"`.

### Content Delivery Network
A [Content Delivery Network](https://docs.microsoft.com/en-gb/azure/cdn/cdn-overview) has been created for the [Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview?toc=/azure/storage/blobs/toc.json) with the host name [assets-getintoteaching.azureedge.net] which has the custom domain [assets-getintoteaching.education.gov.uk]() attached to it.


### DNS
DNS needs to be configured by passing the details from Azure when you create the CDN to the CIP team using a Service Now request.

## Local dependencies

### Node.js and NPM
[Downloading and installing Node.js and npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)

Install NVM: `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash`

Install Node.js: `nvm install 16.17.0`
## Delivery
### Secrets
Using [standard processes](https://github.com/DFE-Digital/bat-platform-building-blocks/tree/master/scripts/fetch_config) developed by DevOps, keys will be maintained in Azure Key Vault.

The Key Vault secret takes the format specified in the `asset-keys.yml` file.

The secret can be easily set the first time using the following make target `make <environment> initialise_secrets`.

* Azure [Shared Access Signature](https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview)

* Script Id, when the script is created a unique id is also generated, you may need to `create` or `clone` a project first, and then store the script id.

### Delivery

Assuming the storage account, DNS, CDN are already in place. To get setup, deploy and update to the script:

* Login to [Google Apps Script](https://script.google.com/home) using an account which has been given access to the shared Google Drive mentioned earlier and the target script if it exists already.

* Clasp requires the user has enabled the Apps Script API. Enable it by visiting [https://script.google.com/home/usersettings](https://script.google.com/home/usersettings) and turning the Google Apps Script API On.

* Create a new Apps Script project and obtain the Script ID under Project Settings or acquire the Script ID from the existing project.

* Add/update this in Key Vault as the SCRIPT_ID using `make <environment> edit_secrets` or add it to a YAML file when the secret is initially created using the Azure CLI.

* Execute `clasp login` and use the same account used earlier.

* Execute the command `make <environment> install`. This will populate the Code.js and clasp.json files with the required project information and upload the script to the specified Apps Script project.

* Execute `clasp open` to go to the Apps Script project and run the createTimeTrigger() to automatically create the trigger to run the uploadAssets() function at the specified time intervals. Authorise any required permissions.

* Share the Apps Script project with the teacher-services-infra Google group to ensure access to it is not lost.

A Makefile has been provided to assist with common tasks:

* **npm** - Install local dependencies for clasp.

* **print_secrets** - This will extract the secrets stored in Azure Key Vault.

* **edit_secrets** - This will extract the secrets stored in Azure Key Vault and enable the user to edit them.

* **install** - Takes the templates and applies the secrets and pushes the script files to Google Apps Scripts,

* **storage_create** - Creates an Azure Storage account using the ARM template, adds a container and enables the static website.

* **storage_sas_create** - Creates a SAS with an expiry of one year.

* **deploy** - Deploys the Apps Script project.

* **initialise_secrets** - Create the Key Vault secret using the contents of the YAML file. Use this for first time setup of the secret.
