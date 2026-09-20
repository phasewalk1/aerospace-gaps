PREFIX ?= $(HOME)/.local
BINDIR := $(PREFIX)/bin

.PHONY: install uninstall test lint help

help:
	@echo "make install [PREFIX=$(PREFIX)]   install aerospace-gaps to $(BINDIR)"
	@echo "make uninstall                    remove it"
	@echo "make test                         run the test suite"
	@echo "make lint                         shellcheck all scripts"

install:
	@mkdir -p "$(BINDIR)"
	@install -m 0755 bin/aerospace-gaps "$(BINDIR)/aerospace-gaps"
	@echo "installed $(BINDIR)/aerospace-gaps"
	@case ":$$PATH:" in *":$(BINDIR):"*) ;; \
	  *) echo "warning: $(BINDIR) is not on your PATH" ;; esac

uninstall:
	@rm -f "$(BINDIR)/aerospace-gaps"
	@echo "removed $(BINDIR)/aerospace-gaps"

test:
	@tests/run.sh

lint:
	@if command -v shellcheck >/dev/null; then \
	  shellcheck bin/aerospace-gaps tests/run.sh && echo "shellcheck clean"; \
	else \
	  echo "shellcheck not installed, skipping"; \
	fi
