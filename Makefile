PORT=1313
HUGO_VERSION=0.134.0
HUGO_PLATFORM_ARCH=linux-amd64
HUGO_URL=https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/hugo_$(HUGO_VERSION)_$(HUGO_PLATFORM_ARCH).tar.gz

.PHONY: serve
serve: bin/hugo
	bin/hugo server -b localhost:$(PORT)

.PHONY: build
build: bin/hugo
	bin/hugo --minify

setup: bin/hugo

bin/hugo: bin/hugo.tar.gz
	tar -xvf bin/hugo.tar.gz -C bin
	touch bin/hugo

bin/hugo.tar.gz:
	mkdir -p bin
	wget $(HUGO_URL) -O bin/hugo.tar.gz

.PHONY: clean
clean:
	rm -rf bin public
