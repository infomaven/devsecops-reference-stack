SHELL := /bin/bash
ENV ?= dev
CLUSTER := devsecops-demo
RUN = @echo "+ $(1)" && $(1)

# The application under test. Empty means the stand-in service; otherwise the
# profile apps/$(APP).yaml is layered after the environment's values file.
# `make select-app` sets it; APP=<name> on the command line overrides.
APP ?= $(shell cat apps/.selected 2>/dev/null)
APP_HELM_ARGS = $(if $(APP),-f apps/$(APP).yaml)
APP_TF_ARGS = $(if $(APP),-var app_values_file=$(CURDIR)/apps/$(APP).yaml)

.PHONY: help cluster select-app db migrate deploy plan smoke policy lint exercise spec-check destroy

help:
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-12s %s\n", $$1, $$2}'

cluster: ## create the local kind cluster
	$(call RUN,kind create cluster --name $(CLUSTER) --config kind/cluster.yaml)
	$(call RUN,kubectl cluster-info --context kind-$(CLUSTER))

select-app: ## choose the stand-in or a real application (ARGS=--help for flags)
	$(call RUN,./scripts/select-app.sh $(ARGS))

db: ## start Postgres and configure it with Ansible
	$(call RUN,docker run -d --name demo-postgres -e POSTGRES_PASSWORD=bootstrap -p 5432:5432 postgres:16-alpine)
	@sleep 5
	$(call RUN,ansible-playbook -i ansible/inventory/hosts.ini ansible/site.yml)

migrate: ## apply SQL migrations through Ansible
	$(call RUN,ansible-playbook -i ansible/inventory/hosts.ini ansible/site.yml --tags migrate)

deploy: ## terraform apply for one environment
	$(call RUN,terraform -chdir=terraform/envs/$(ENV) init -input=false)
	$(call RUN,terraform -chdir=terraform/envs/$(ENV) apply -auto-approve -input=false $(APP_TF_ARGS))

plan: ## terraform plan for one environment
	$(call RUN,terraform -chdir=terraform/envs/$(ENV) init -input=false)
	$(call RUN,terraform -chdir=terraform/envs/$(ENV) plan -input=false $(APP_TF_ARGS))

smoke: ## post-deploy checks
	$(call RUN,./scripts/smoke-test.sh $(ENV))

policy: ## render the chart and test it against the Rego policies
	$(call RUN,helm template paymentsvc helm/paymentsvc -f helm/paymentsvc/values-$(ENV).yaml $(APP_HELM_ARGS) | conftest test --policy policy/kubernetes -)

lint: ## all linters
	$(call RUN,terraform fmt -check -recursive terraform)
	$(call RUN,helm lint helm/paymentsvc -f helm/paymentsvc/values-dev.yaml)
	$(call RUN,yamllint -s .)
	$(call RUN,ansible-lint ansible)

exercise: ## run the security-engineer-toolkit loop against this repo
	@echo "Static scanners (whatever is installed locally):"
	-$(call RUN,gitleaks detect --no-banner --redact)
	-$(call RUN,semgrep --config auto --error scripts ansible)
	-$(call RUN,trivy fs --severity HIGH,CRITICAL --ignore-unfixed .)
	-$(call RUN,checkov --directory terraform --framework terraform --compact)
	@echo
	@echo "Then, in Claude Code, with the toolkit's commands installed:"
	@echo "  /setup-target ."
	@echo "  /security-review          # Scenario B: this repo is one generated diff"
	@echo "  /security-sweep scripts"
	@echo "  /security-sweep ansible"
	@echo "  /remediation-note <what you fixed>"
	@echo
	@echo "Record each finding in findings/. See docs/SECURITY_AUDIT_STEPS.md."

spec-check: ## does the repository match spec/FEATURES.md
	$(call RUN,bash scripts/spec-check.sh)

destroy: ## tear down
	-$(call RUN,terraform -chdir=terraform/envs/$(ENV) destroy -auto-approve $(APP_TF_ARGS))
	-$(call RUN,docker rm -f demo-postgres)
	-$(call RUN,kind delete cluster --name $(CLUSTER))
