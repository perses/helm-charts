# Copyright The Perses Authors
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include Makefile.tools

GO                    ?= go
CONTAINER_CLI         ?= docker
CHARTS                := $(wildcard charts/*)

.PHONY: checkdocs
checkdocs:
	@echo ">> check format markdown docs"
	@make fmt-docs
	@git diff --exit-code -- *.md

.PHONY: fmt-docs
fmt-docs: mdox
	@echo ">> format markdown document"
	$(MDOX) fmt --soft-wraps -l $$(find . -name '*.md' -not -path './docs/*' -print) --links.validate.config-file=./.mdox.validate.yaml

.PHONY: helm-lint
helm-lint: helm
	@for chart in $(CHARTS); do \
		echo ">> linting $$chart"; \
		$(HELM) lint --strict $$chart; \
	done

.PHONY: helm-template
helm-template: helm
	@for chart in $(CHARTS); do \
		echo ">> rendering $$chart"; \
		$(HELM) template test-release $$chart > /dev/null; \
	done

.PHONY: helm-validate
helm-validate: helm-lint helm-template

KIND_CLUSTER_NAME    ?= helm-charts-test
CERT_MANAGER_VERSION ?= $(shell grep cert-manager-version .github/env | cut -d= -f2)
KIND_VERSION         ?= $(shell grep kind-version .github/env | cut -d= -f2)
KIND_IMAGE           ?= $(shell grep kind-image .github/env | cut -d= -f2)

.PHONY: kind-create
kind-create: ## Create a kind cluster for local testing.
	@kind create cluster --name $(KIND_CLUSTER_NAME) --image $(KIND_IMAGE) --wait 60s
	@echo ">> installing cert-manager $(CERT_MANAGER_VERSION)"
	@kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/$(CERT_MANAGER_VERSION)/cert-manager.yaml
	@kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=120s

.PHONY: kind-delete
kind-delete: ## Delete the kind cluster.
	@kind delete cluster --name $(KIND_CLUSTER_NAME)

.PHONY: helm-test
helm-test: helm kind-create ## Install and test charts on kind. Use CHART=charts/<name> to test a single chart.
	@for chart in $(or $(CHART),$(CHARTS)); do \
		release=$$(basename $$chart); \
		echo ">> installing $$chart as $$release"; \
		$(HELM) install $$release $$chart --wait --timeout 120s; \
		echo ">> testing $$release"; \
		$(HELM) test $$release; \
	done
	@echo ">> cleaning up kind cluster"
	@make kind-delete

.PHONY: sync-crds
sync-crds: ## Sync CRDs from perses-operator (version from Chart.yaml appVersion).
	@./hack/sync-crds.sh

.PHONY: update-helm-readme
update-helm-readme:
	@for chart in $(CHARTS); do \
		echo ">> generating docs for $$chart"; \
		$(CONTAINER_CLI) run --rm --volume "$$(pwd)/$$chart:/helm-docs" -u $$(id -u) jnorwood/helm-docs:latest; \
	done
	@make fmt-docs
