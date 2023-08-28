# Copyright 2023 The Perses Authors
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

GO                    ?= go
MDOX                  ?= mdox

.PHONY: checkdocs
checkdocs:
	@echo ">> check format markdown docs"
	@make fmt-docs
	@git diff --exit-code -- *.md

.PHONY: fmt-docs
fmt-docs:
	@echo ">> format markdown document"
	$(MDOX) fmt --soft-wraps -l $$(find . -name '*.md' -print) --links.validate.config-file=./.mdox.validate.yaml

.PHONY: update-go-deps
update-go-deps:
	@echo ">> updating Go dependencies"
	@for m in $$($(GO) list -mod=readonly -m -f '{{ if and (not .Indirect) (not .Main)}}{{.Path}}{{end}}' all); do \
		$(GO) get -d $$m; \
	done


.PHONY: update-helm-readme
update-helm-readme:
	@docker run --rm --volume "$$(pwd)/charts/perses:/helm-docs" -u $$(id -u) jnorwood/helm-docs:latest
	@make fmt-docs