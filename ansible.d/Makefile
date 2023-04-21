SHELL:=/bin/bash
.PHONY: help
help: ## Display callable targets.
	@echo "Reference card for usual actions."
	@echo "Here are available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

.PHONY: all ## Run all.yml playbook.
all: ## Run all.yml playbook.
	ansible-playbook -i environments/$(env)/inventory playbooks/all.yml

.PHONY: essential ## Run essential.yml playbook.
essential: ## Run essential.yml playbook.
	ansible-playbook -i environments/$(env)/inventory playbooks/essential.yml

.PHONY: dalibo_labs ## Run dalibo_labs.yml playbook.
dalibo_labs: ## Run dalibo_labs.yml playbook.
	ansible-playbook -i environments/$(env)/inventory playbooks/dalibo_labs.yml

.PHONY: database_essential ## Run database_essential.yml playbook.
database_essential: ## Run database_essential.yml playbook.
	ansible-playbook -i environments/$(env)/inventory playbooks/database_essential.yml

.PHONY: pglift_instance_essential ## Run pglift_instance_essential.yml playbook.
pglift_instance_essential: ## Run pglift_instance_essential.yml playbook.
	ansible-playbook -i environments/$(env)/inventory playbooks/pglift_instance_essential.yml

.PHONY: init ## Init the requirements.
init: ## Init the requirements.
	ansible-galaxy install --force -r ./requirements/roles.yml
	ansible-galaxy install -r ./requirements/collections.yml

.PHONY: tar ## Create tar.gz archive for the collection.
tar: ## Create tar.gz archive for the collection.
	rm -rf ./_build
	mkdir -p ./_build
	cp -R ~/.ansible/collections/ansible_collections/dalibo/essential ./_build
	tar cvzf ./_build/dalibo-essential-$(version).tar.gz -C ./_build ./essential
