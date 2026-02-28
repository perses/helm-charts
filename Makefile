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
MDOX                  ?= mdox
CONTAINER_CLI         ?= docker
CHARTS                := $(wildcard charts/*)

.PHONY: checkdocs
checkdocs:
	@echo ">> check format markdown docs"
	@make fmt-docs
	@git diff --exit-code -- *.md

.PHONY: fmt-docs
fmt-docs:
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

.PHONY: update-helm-readme
update-helm-readme:
	@for chart in $(CHARTS); do \
		echo ">> generating docs for $$chart"; \
		$(CONTAINER_CLI) run --rm --volume "$$(pwd)/$$chart:/helm-docs" -u $$(id -u) jnorwood/helm-docs:latest; \
	done
	@make fmt-docs