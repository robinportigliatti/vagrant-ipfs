ifdef env
	EXTRA_ARGS:=--env=$(env)
endif
ifdef provshell
	EXTRA_ARGS:=$(EXTRA_ARGS) --shell=$(provshell)
endif

SHELL:=/bin/bash
.PHONY: help
help: ## Display callable targets.
	@echo "Reference card for usual actions."
	@echo "Here are available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

CURRENT_DIR=$(shell pwd)

.PHONY: all ## Up all VM and provision them.
all: up provision## Up all VM and provision them.

.PHONY: init ## Init ansible roles and collections.
init: ## Init ansible roles and collections.
	$(MAKE) -C ../ansible.d init

.PHONY: up ## Up all VM. Also init ansible roles and collections.
up: init ## Up all VM. Also init ansible roles and collections.
	vagrant $(EXTRA_ARGS) up --no-provision

.PHONY: reset ## Reset all VM. Destroy them and create them.
reset: destroy all ## Reset all VM. Destroy them and create them.

.PHONY: provision ## Provision all VM. Also init ansible roles and collections.
provision: ## Provision all VM. Also init ansible roles and collections.
	vagrant $(EXTRA_ARGS) provision

.PHONY: destroy ## Destroy all VM.
destroy: ## Destroy all VM.
	vagrant $(EXTRA_ARGS) destroy --force

.PHONY: update ## Update all box.
update: ## Update all box.
	vagrant $(EXTRA_ARGS) box update
		
.PHONY: cert-cfssl ## Create certificates with cfssl.
cert-cfssl: ## Create certificates with cfssl.
	rm -rf ./cfss/*.pem
	bash ./cfssl/generate_certification_authority.bash
	bash ./cfssl/generate_server_certificate.bash etcd1 192.168.60.21 192.168.60.1
	bash ./cfssl/generate_server_certificate.bash etcd2 192.168.60.22 192.168.60.1
	bash ./cfssl/generate_server_certificate.bash etcd3 192.168.60.23 192.168.60.1
	bash ./cfssl/generate_server_certificate.bash pg1 192.168.60.11 192.168.60.1
	bash ./cfssl/generate_server_certificate.bash pg2 192.168.60.12 192.168.60.1
	bash ./cfssl/generate_server_certificate.bash pg3 192.168.60.13 192.168.60.1
	bash ./cfssl/generate_server_certificate.bash pgbouncer1 192.168.60.41 192.168.60.1
	bash ./cfssl/generate_server_certificate.bash pgbouncer2 192.168.60.42 192.168.60.1
	bash ./cfssl/generate_server_certificate.bash pgbouncer3 192.168.60.43 192.168.60.1
	bash ./cfssl/generate_server_certificate.bash temboard1 192.168.60.31 192.168.60.1

.PHONY: cert-openssl ## Create certificates with openssl.
cert-openssl: ## Create certificates with openssl.
	sudo rm -rf $(CURRENT_DIR)/../openssl/ca
	sudo rm -rf $(CURRENT_DIR)/../openssl/*.pem
	ansible-playbook ../ansible.d/playbooks/openssl.yml --extra-vars="openssl_root_dir='$(CURRENT_DIR)/../openssl/ca' openssl_custom_subjectAltName=',IP:192.168.60.1'" -i ../ansible.d/environments/advanced/inventory
	sudo chown -R robin:robin $(CURRENT_DIR)/../openssl
	sudo chmod 755 -R $(CURRENT_DIR)/../openssl
	cat $(CURRENT_DIR)/../openssl/ca/intermediate-ca/certs/intermediate-ca-cert.pem $(CURRENT_DIR)/../openssl/ca/certs/ca.cert.pem > $(CURRENT_DIR)/../openssl/ca-chain-cert.pem
	cp $(CURRENT_DIR)/../openssl/ca/intermediate-ca/certs/*.pem $(CURRENT_DIR)/../openssl
	cp $(CURRENT_DIR)/../openssl/ca/intermediate-ca/private/*.pem $(CURRENT_DIR)/../openssl
	cp  $(CURRENT_DIR)/../openssl/ca/private/*.pem $(CURRENT_DIR)/../openssl
	cp  $(CURRENT_DIR)/../openssl/ca/certs/*.pem $(CURRENT_DIR)/../openssl
	rm -rf $(CURRENT_DIR)/../openssl/ca

cert-openssl2: ## Create certificates with openssl.
	rm -rf $(CURRENT_DIR)/../openssl/ca
	rm -rf $(CURRENT_DIR)/../openssl/*.pem
	bash $(CURRENT_DIR)/../openssl/create_the_root_pair.bash
	bash $(CURRENT_DIR)/../openssl/create_the_intermediate_pair.bash
	bash $(CURRENT_DIR)/../openssl/sign_server_and_client_certificates.bash pg1 192.168.60.11 192.168.60.1
	bash $(CURRENT_DIR)/../openssl/sign_server_and_client_certificates.bash pg2 192.168.60.12 192.168.60.1
	bash $(CURRENT_DIR)/../openssl/sign_server_and_client_certificates.bash pg3 192.168.60.13 192.168.60.1
	bash $(CURRENT_DIR)/../openssl/sign_server_and_client_certificates.bash etcd1 192.168.60.21 192.168.60.1
	bash $(CURRENT_DIR)/../openssl/sign_server_and_client_certificates.bash etcd2 192.168.60.22 192.168.60.1
	bash $(CURRENT_DIR)/../openssl/sign_server_and_client_certificates.bash etcd3 192.168.60.23 192.168.60.1
	bash $(CURRENT_DIR)/../openssl/sign_server_and_client_certificates.bash pgbouncer1 192.168.60.41 192.168.60.1
	bash $(CURRENT_DIR)/../openssl/sign_server_and_client_certificates.bash pgbouncer2 192.168.60.42 192.168.60.1
	bash $(CURRENT_DIR)/../openssl/sign_server_and_client_certificates.bash pgbouncer3 192.168.60.43 192.168.60.1
	bash $(CURRENT_DIR)/../openssl/sign_server_and_client_certificates.bash temboard1 192.168.60.31 192.168.60.1
	bash $(CURRENT_DIR)/../openssl/sign_server_and_client_certificates.bash pgbackrest1 192.168.60.32 192.168.60.1
	cat $(CURRENT_DIR)/../openssl/ca/ca-etcd/certs/ca-etcd-cert.pem $(CURRENT_DIR)/../openssl/ca/certs/ca-cert.pem > $(CURRENT_DIR)/../openssl/ca/ca-etcd/certs/ca-chain-cert.pem
	cp $(CURRENT_DIR)/../openssl/ca/ca-etcd/certs/*.pem $(CURRENT_DIR)/../openssl
	cp  $(CURRENT_DIR)/../openssl/ca/ca-etcd/private/*.pem $(CURRENT_DIR)/../openssl
	cp $(CURRENT_DIR)/../openssl/ca/certs/*.pem $(CURRENT_DIR)/../openssl
	cp $(CURRENT_DIR)/../openssl/ca/private/*.pem $(CURRENT_DIR)/../openssl
	rm -rf $(CURRENT_DIR)/../openssl/ca