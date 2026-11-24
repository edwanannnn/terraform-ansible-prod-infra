.PHONY: fmt validate plan apply destroy provision lint

TF_DIR := terraform
ANSIBLE_DIR := ansible

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

validate:
	terraform -chdir=$(TF_DIR) init -backend=false
	terraform -chdir=$(TF_DIR) validate

plan:
	terraform -chdir=$(TF_DIR) plan

apply:
	terraform -chdir=$(TF_DIR) apply

destroy:
	terraform -chdir=$(TF_DIR) destroy

provision:
	ANSIBLE_CONFIG=$(ANSIBLE_DIR)/ansible.cfg ansible-playbook -i $(ANSIBLE_DIR)/inventory.ini $(ANSIBLE_DIR)/playbook.yml

lint:
	terraform -chdir=$(TF_DIR) fmt -check -recursive
	ansible-lint $(ANSIBLE_DIR)/playbook.yml
