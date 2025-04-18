PORT=1313
HUGO_VERSION=0.134.1
HUGO_PLATFORM_ARCH=linux-amd64
# Check latest release here: https://github.com/gohugoio/hugo/releases
HUGO_URL=https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/hugo_$(HUGO_VERSION)_$(HUGO_PLATFORM_ARCH).tar.gz

BIN_DIR=bin
HUGO=$(BIN_DIR)/hugo

.PHONY: all
all: build

.PHONY: build
build: $(HUGO)
	$(HUGO) --minify

.PHONY: serve
serve: $(HUGO)
	$(HUGO) server -b localhost:$(PORT)

setup: $(HUGO)

$(HUGO): $(BIN_DIR)/hugo.tar.gz
	tar -xvf $(BIN_DIR)/hugo.tar.gz -C $(BIN_DIR)
	touch $(HUGO)

$(BIN_DIR)/hugo.tar.gz:
	mkdir -p $(BIN_DIR)
	wget $(HUGO_URL) -O $(BIN_DIR)/hugo.tar.gz

.PHONY: deploy
deploy: build
	if [ -z "$(REMOTE_HOST)" ]; then echo "REMOTE_HOST is not set"; exit 1; fi
	if [ -z "$(REMOTE_USER)" ]; then echo "REMOTE_USER is not set"; exit 1; fi
	if [ -z "$(REMOTE_PATH)" ]; then echo "REMOTE_PATH is not set"; exit 1; fi
	rsync -avz --delete public/ $(REMOTE_HOST):$(REMOTE_PATH)
	ssh $(REMOTE_HOST) sudo chown -R $(REMOTE_USER):www-data $(REMOTE_PATH)

.PHONY: update-gpg
update-gpg:
	gpg --armor --export 9D061C14296CE3DBBAF6C5CB7B9F71950D93191B > static/davidisaksson.asc

.PHONY: clean
clean:
	rm -rf $(BIN_DIR) public
