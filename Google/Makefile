ifndef VERBOSE
.SILENT:
endif

ASSET_SECRETS=ASSET-KEYS

.PHONY: development
development:
	$(eval export KEY_VAULT=s146d01-kv)
	$(eval export AZ_SUBSCRIPTION=s146-getintoteachingwebsite-development)

.PHONY: production
production:
	$(eval export KEY_VAULT=s146p01-kv)
	$(eval export AZ_SUBSCRIPTION=s146-getintoteachingwebsite-production)

set-azure-account: ${environment}
	echo "Logging on to ${AZ_SUBSCRIPTION}"
	az account set -s ${AZ_SUBSCRIPTION}

clean:
	[ ! -f fetch_config.rb ]  \
	    rm -f fetch_config.rb \
	    || true

install-fetch-config:
	[ ! -f fetch_config.rb ]  \
	    && echo "Installing fetch_config.rb" \
	    && curl -s https://raw.githubusercontent.com/DFE-Digital/bat-platform-building-blocks/master/scripts/fetch_config/fetch_config.rb -o fetch_config.rb \
	    && chmod +x fetch_config.rb \
	    || true

pip:
	pip install jinja2-cli
npm:
	[ ! -f /usr/local/bin/clasp ]  \
	    && npm install @google/clasp -g \
	    || true
	echo using Clasp version `clasp --version`


edit_secrets:
	./fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT}/${ASSET_SECRETS} -e -d azure-key-vault-secret:${KEY_VAULT}/${ASSET_SECRETS} -f yaml -c

install: pip npm install-fetch-config set-azure-account
	./fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT}/${ASSET_SECRETS}  -f shell-env-var -d command -- jinja2 Code.js.tmpl > Code.js
	./fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT}/${ASSET_SECRETS}  -f shell-env-var -d command -- jinja2 clasp.json.tmpl > .clasp.json
	echo "Push Project" 
