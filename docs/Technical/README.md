# Technical
Securely connecting Google Drive to Microsoft Azure, and providing a bespoke domain

![Overview](./asset.png)

## Google
### Google Drive
The [Shared drive](https://drive.google.com/drive/folders/0AJ6YEVtSfOQVUk9PVA) has been created by the [Digital Tools Support](https://sites.google.com/digital.education.gov.uk/digitaltools/home) team and **Manager** access has been granted to a number of team members.

Team members who need to manage assets can be granted **Contributor** access by any of the managers.

### Google Scripts
Periodically a [Google Script ](https://github.com/DFE-Digital/GITISContent/tree/main/Google) needs to run. This will transfer the assets from the [Shared drive](https://drive.google.com/drive/folders/0AJ6YEVtSfOQVUk9PVA) to Azure.

The script needs to have a [Azure SAS Key](https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview) embedded into it, which gives access to the Azure Storage account. Since this key is sensistive, it is stored as a GitHub Secret and injected into the script at deployment time.


## Azure
### Storage Accounts
Within the Azure subscription s146-getintoteachingwebsite-production the [Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview?toc=/azure/storage/blobs/toc.json) **s146p01gitiscontent** has been created. This storage account has a container called "**content**" which has been set as a [Static Website](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website)

A [Shared Access signature](https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview) has been created for this [Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview?toc=/azure/storage/blobs/toc.json)

### Content Delivery Network
A [Content Delivery Network](https://docs.microsoft.com/en-gb/azure/cdn/cdn-overview) has been created for the  [Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview?toc=/azure/storage/blobs/toc.json) with the host name [assets-getintoteaching.azureedge.net] which has the custom domain [assets-getintoteaching.education.gov.uk]() attached to it.


### DNS
DNS needs to be configured by passing the details from Azure when you create the CDN to the CIP team using a Service Now Ticket.

## Delivery
### Secrets
Using [standard processes](https://github.com/DFE-Digital/bat-platform-building-blocks/tree/master/scripts/fetch_config) developed by DevOps, keys will be maintained in Azure Key_vault 

* Azure [Shared Access signature](https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview) 

* Script Id, when the script is created a unique id is also generated, you may need to `create` or `clone` a project first, and then store the script id.

* Google Credentials, You will need to go to the [Google Console](https://console.cloud.google.com/apis/credentials?project=analysis-283611) and create a new [OAuth 2.0 Client ID](https://cloud.google.com/docs/authentication?_ga=2.57888426.-1487445474.1614340844&_gac=1.249058805.1614679555.Cj0KCQiA4feBBhC9ARIsABp_nbV09y-DZeJFsJwvTBNFQCM4DY-2-2dgU8ZJxFvPW4no2Rux2z3ZfnwaAluvEALw_wcB), When choosing your Application Type it is **_important_** that you select **Desktop App**. Once you have created the credentials you will be able to download the json file.

```
{"installed":{
       "client_id":"xxxxxxxxxx.apps.googleusercontent.com",
       "project_id":"xxxxxxxxxxxxx",
       "auth_uri":"https://accounts.google.com/o/oauth2/auth",
       "token_uri":"https://oauth2.googleapis.com/token",
       "auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs",
       "client_secret":"xxxxxxxxxxxxx",
       "redirect_uris":["urn:ietf:wg:oauth:2.0:oob","http://localhost"]}}
 
```


### Delivery

Clasp requires the User has enabled the Apps Script API. Enable it by visiting [https://script.google.com/home/usersettings.
](https://script.google.com/home/usersettings)

A Makefile has been provided to assist with common tasks:

* **edit_secrets** - This process will extract the secrets stored in Azure Key-Vault and enable the user to amend them.

* **generate_credentials** - The secrets are Google Credentials, they need to be generated into a `creds.json` file to allow clasp to use them.

* **install** - Takes the templates, applies the secrets and pushes them up to Google Scripts. 



