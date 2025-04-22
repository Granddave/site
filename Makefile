PORT=1313
HUGO_VERSION=0.146.6
HUGO_PLATFORM_ARCH=linux-amd64
# Check latest release here: https://github.com/gohugoio/hugo/releases
HUGO_URL=https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/hugo_$(HUGO_VERSION)_$(HUGO_PLATFORM_ARCH).tar.gz

BIN_DIR=bin
HUGO=$(BIN_DIR)/hugo

SHELL := /bin/bash
.SHELLFLAGS := -e -o pipefail -c

# Default target
.PHONY: all
all: build

# Build for production
.PHONY: build
build: $(HUGO)
	$(HUGO) --minify --gc --ignoreCache --destination public

# Local development
.PHONY: serve
serve: $(HUGO)
	$(HUGO) server -b localhost:$(PORT)

# Set up Hugo
.PHONY: setup
setup: $(HUGO)

# Update the Hugo binary
.PHONY: update-hugo
update-hugo: clean-hugo setup

# Extract the Hugo binary
$(HUGO): $(BIN_DIR)/hugo.tar.gz
	mkdir -p $(BIN_DIR)
	tar -xzvf $(BIN_DIR)/hugo.tar.gz -C $(BIN_DIR)
	chmod +x $(HUGO)
	touch $(HUGO)
	@echo "Hugo $(HUGO_VERSION) installed in $(BIN_DIR)"

# Download Hugo tarball
$(BIN_DIR)/hugo.tar.gz:
	mkdir -p $(BIN_DIR)
	wget $(HUGO_URL) -O $(BIN_DIR)/hugo.tar.gz || { \
		echo "Failed to download Hugo. Please check the URL: $(HUGO_URL)"; \
		exit 1; \
	}

# Deploy to production
.PHONY: deploy
deploy: build
	if [ -z "$(REMOTE_HOST)" ]; then echo "REMOTE_HOST is not set"; exit 1; fi
	if [ -z "$(REMOTE_USER)" ]; then echo "REMOTE_USER is not set"; exit 1; fi
	if [ -z "$(REMOTE_PATH)" ]; then echo "REMOTE_PATH is not set"; exit 1; fi
	rsync -avz --delete public/ $(REMOTE_HOST):$(REMOTE_PATH)
	ssh $(REMOTE_HOST) sudo chown -R $(REMOTE_USER):www-data $(REMOTE_PATH)
	@echo "Deployment to completed."

.PHONY: update-gpg
update-gpg:
	gpg --armor --export 9D061C14296CE3DBBAF6C5CB7B9F71950D93191B > static/davidisaksson.asc

.PHONY: clean
clean-hugo:
	rm -rf $(BIN_DIR)

.PHONY: clean
clean: clean-hugo
	rm -rf public resources
