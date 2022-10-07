ifndef VERBOSE
.SILENT:
endif

ASSET_SECRETS=ASSET-KEYS

.PHONY: development
development:
	$(eval export KEY_VAULT=s146d01-kv)
	$(eval export AZ_SUBSCRIPTION=s146-getintoteachingwebsite-development)
	$(eval export TRIGGER_MINUTES=10)
	$(eval export STORAGE_NAME=s146d01gitiscontent)
	$(eval export RESOURCE_GROUP=s146d01-rg)

.PHONY: production
production:
	$(eval export KEY_VAULT=s146p01-kv)
	$(eval export AZ_SUBSCRIPTION=s146-getintoteachingwebsite-production)
	$(eval export TRIGGER_MINUTES=10)
	$(eval export STORAGE_NAME=s146p01gitiscontent)
	$(eval export RESOURCE_GROUP=s146p01-rg)

set-azure-account: az-login
	echo "Setting Azure subscription to ${AZ_SUBSCRIPTION}"
	az account set -s ${AZ_SUBSCRIPTION}

az-login:
	$(eval export AZURE_SUB=$(shell az account show | jq -r .name))
	echo "AZURE_SUB: ${AZURE_SUB}"
	if [ -z "${AZURE_SUB}" ]; then \
		echo "Not logged in to Azure running 'az login'"; \
		az login --only-show-errors; \
	else \
		echo "Logged in to Azure with subscription: ${AZURE_SUB}"; \
	fi

clean:
	rm -f Google/Code.js Google/.clasp.json Google/creds.json Google/Trigger.js
	[ ! -f fetch_config.rb ]  \
	    `rm -f fetch_config.rb` \
	    || true

install-fetch-config:
	[ ! -f fetch_config.rb ]  \
	    && echo "Installing fetch_config.rb" \
	    && curl -s https://raw.githubusercontent.com/DFE-Digital/bat-platform-building-blocks/master/scripts/fetch_config/fetch_config.rb -o fetch_config.rb \
	    && chmod +x fetch_config.rb \
	    || true

npm:
	$(eval export CLASP_FOLDER=$(shell which clasp))
	if [ -z "${CLASP_FOLDER}" ]; then \
		echo "clasp not found. Installing..."; \
		npm install @google/clasp -g; \
		echo installed clasp version: `clasp --version`; \
	else \
		echo "'which clasp' found clasp at: ${CLASP_FOLDER}"; \
		echo using clasp version `clasp --version`; \
	fi

generate_credentials: npm install-fetch-config set-azure-account
	./fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT}/${ASSET_SECRETS} -f shell-env-var -d command -- erb ./Google/creds.json.tmpl > ./Google/creds.json
	cd Google && clasp login --creds ./Google/creds.json

storage_parameters: install-fetch-config set-azure-account
	echo "Storage Parameters..."
	./fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT}/${ASSET_SECRETS} -f shell-env-var -d command -- erb ./azure/storage_parameters.json.tmpl > ./azure/storage_parameters.json

storage_create: install-fetch-config set-azure-account
	echo "Storage Create..."
	$(eval export DEPLOYMENT_NAME=makefile_storage_create_$(shell date -u -v +365d '+%Y-%m-%dT%H%MZ'))
	make storage_parameters
	az deployment group create --name ${DEPLOYMENT_NAME} --resource-group ${RESOURCE_GROUP} --template-file ./azure/storage_template.json --parameters ./azure/storage_parameters.json
	az storage container create -n content --account-name ${STORAGE_NAME}
	az storage blob service-properties update --account-name ${STORAGE_NAME} --static-website

storage_sas_create: set-azure-account
	$(eval export SAS_EXPIRY=$(shell date -u -v +365d '+%Y-%m-%dT%H:%MZ'))
	$(eval export SAS_START=$(shell date -u '+%Y-%m-%dT%H:%MZ'))
	az storage container generate-sas --account-name ${STORAGE_NAME} -n content --permissions racw --start ${SAS_START} --expiry ${SAS_EXPIRY} --https-only

print_secrets: install-fetch-config set-azure-account
	./fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT}/${ASSET_SECRETS} -f yaml

edit_secrets: install-fetch-config set-azure-account
	./fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT}/${ASSET_SECRETS} -e -d azure-key-vault-secret:${KEY_VAULT}/${ASSET_SECRETS} -f yaml -c

install: install-fetch-config set-azure-account
	echo "Install..."
	./fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT}/${ASSET_SECRETS} -f shell-env-var -d command -- erb ./Google/Code.js.tmpl > ./Google/Code.js
	./fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT}/${ASSET_SECRETS} -f shell-env-var -d command -- erb ./Google/Trigger.js.tmpl > ./Google/Trigger.js
	./fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT}/${ASSET_SECRETS} -f shell-env-var -d command -- erb ./Google/clasp.json.tmpl > ./Google/.clasp.json

deploy: npm install
	echo "Deploy..."
	cd Google && clasp push

initialise_secrets: set-azure-account
	az keyvault secret set --vault-name ${KEY_VAULT} --name ${ASSET_SECRETS} --file ./azure/asset-keys.yml

clasp_status: npm
	echo "Listing clasp project files ..."
	cd Google && clasp status

clasp_settings: npm
	echo "Show clasp settings ..."
	cd Google && clasp settings

clasp_list: npm
	echo "List clasp projects ..."
	cd Google && clasp list

clasp_login: npm
	echo "Login with clasp ..."
	cd Google && clasp login

clasp_open: npm
	echo "Open current clasp project ..."
	cd Google && clasp open
