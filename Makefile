.PHONY: console test

USER=dev
HOME_DIR=/home/dev
WORKDIR=$(HOME_DIR)/pipelines
INTERACTIVE_SESSION=\
          -v $$PWD/home_dir:$(HOME_DIR) \
          -v $$PWD/..:$(WORKDIR) \
          -e HOME=$(HOME_DIR) \
          -e MIX_ENV=test \
          --workdir=$(WORKDIR)/util \
          -it renderedtext/elixir-dev:1.5.1-v2 \

console:
	docker run $(INTERACTIVE_SESSION) /bin/bash

test:
	docker run --user=$(USER) $(INTERACTIVE_SESSION) \
          mix do local.hex --force, local.rebar --force, deps.get, test
