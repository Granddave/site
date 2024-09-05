PORT=1313
HUGO_VERSION=0.134.0
HUGO_PLATFORM_ARCH=linux-amd64
HUGO_URL=https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/hugo_$(HUGO_VERSION)_$(HUGO_PLATFORM_ARCH).tar.gz

.PHONY: all
all: build

.PHONY: build
build: bin/hugo
	bin/hugo --minify

.PHONY: serve
serve: bin/hugo
	bin/hugo server -b localhost:$(PORT)

setup: bin/hugo

bin/hugo: bin/hugo.tar.gz
	tar -xvf bin/hugo.tar.gz -C bin
	touch bin/hugo

bin/hugo.tar.gz:
	mkdir -p bin
	wget $(HUGO_URL) -O bin/hugo.tar.gz

.PHONY: deploy
deploy: build
	if [ -z "$(REMOTE_HOST)" ]; then echo "REMOTE_HOST is not set"; exit 1; fi
	if [ -z "$(REMOTE_USER)" ]; then echo "REMOTE_USER is not set"; exit 1; fi
	if [ -z "$(REMOTE_PATH)" ]; then echo "REMOTE_PATH is not set"; exit 1; fi
	rsync -avz --delete public/ $(REMOTE_HOST):$(REMOTE_PATH)
	ssh $(REMOTE_HOST) sudo chown -R $(REMOTE_USER):www-data $(REMOTE_PATH)

.PHONY: clean
clean:
	rm -rf bin public
