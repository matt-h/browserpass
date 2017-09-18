SHELL := /usr/bin/env bash
CHROME := $(shell which google-chrome 2>/dev/null || which google-chrome-stable 2>/dev/null || which chromium 2>/dev/null || which chrome 2>/dev/null)
PEM := $(shell find . -name "chrome-browserpass.pem")
JS_OUTPUT := chrome/script.js chrome/inject.js

.PHONY: empty
empty: js static-files browserpass-linux64
	sed -i -e "s/%%replace%%/\/usr\/bin\/browserpass/" chrome-host.json
	sudo install -D chrome-host.json /etc/chromium/native-messaging-hosts/com.dannyvankooten.browserpass.json
	sudo mv browserpass-linux64 /usr/bin/browserpass

.PHONY: chrome
chrome:
ifeq ($(PEM),./chrome-browserpass.pem)
	/usr/bin/chromium --disable-gpu --pack-extension=./chrome --pack-extension-key=$(PEM)
else
	/usr/bin/chromium --disable-gpu --pack-extension=./chrome
	rm ./chrome.pem
	mv chrome.crx chrome-browserpass.crx

.PHONY: firefox
firefox:
	cp chrome/{*.html,*.css,*.js,*.png,*.svg} firefox/

.PHONY: js
js: $(JS_OUTPUT)

chrome/script.js: chrome/script.browserify.js
	browserify chrome/script.browserify.js -o chrome/script.js

chrome/inject.js: chrome/inject.browserify.js
	browserify chrome/inject.browserify.js -o chrome/inject.js

.PHONY: static-files
static-files: chrome/host.json firefox/host.json
	cp chrome/host.json chrome-host.json
	cp firefox/host.json firefox-host.json

browserpass: cmd/browserpass/ pass/ browserpass.go
	go build -o $@ ./cmd/browserpass

browserpass-linux64: cmd/browserpass/ pass/ browserpass.go
	env GOOS=linux GOARCH=amd64 go build -o $@ ./cmd/browserpass

browserpass-windows64: cmd/browserpass/ pass/ browserpass.go
	env GOOS=windows GOARCH=amd64 go build -o $@.exe ./cmd/browserpass

browserpass-darwinx64: cmd/browserpass/ pass/ browserpass.go
	env GOOS=darwin GOARCH=amd64 go build -o $@ ./cmd/browserpass

browserpass-openbsd64: cmd/browserpass/ pass/ browserpass.go
	env GOOS=openbsd GOARCH=amd64 go build -o $@ ./cmd/browserpass

browserpass-freebsd64: cmd/browserpass/ pass/ browserpass.go
	env GOOS=freebsd GOARCH=amd64 go build -o $@ ./cmd/browserpass

clean:
	rm -f browserpass-*
	rm -rf release
	git clean -fdx chrome/
	git clean -fdx firefox/
	rm -f *.crx
	rm -f *-host.json

sign:
	for file in release/*; do \
		gpg --detach-sign "$$file"; \
	done

.PHONY: static-files chrome firefox
release: static-files chrome firefox browserpass-linux64 browserpass-darwinx64 browserpass-openbsd64 browserpass-freebsd64 browserpass-windows64
	mkdir -p release
	cp chrome-browserpass.crx release/
	zip -jFS "release/chrome" chrome/* chrome-browserpass.crx
	zip -jFS "release/firefox" firefox/*
	zip -FS "release/browserpass-linux64" browserpass-linux64 *-host.json chrome-browserpass.crx install.sh README.md LICENSE
	zip -FS "release/browserpass-darwinx64" browserpass-darwinx64 *-host.json chrome-browserpass.crx install.sh README.md LICENSE
	zip -FS "release/browserpass-openbsd64" browserpass-openbsd64 *-host.json chrome-browserpass.crx install.sh README.md LICENSE
	zip -FS "release/browserpass-freebsd64" browserpass-freebsd64 *-host.json chrome-browserpass.crx install.sh README.md LICENSE
	zip -FS "release/browserpass-windows64" browserpass-windows64.exe *-host.json chrome-browserpass.crx *.ps1 README.md LICENSE
