export LANG=en_US.UTF-8

.DEFAULT_GOAL := build

# * Processing dictionary data into one combined file
src/_data: src/_data/combined.json src/_data/kisaragi_dict.json

src/_data/combined.json: dicts/moedict-data-twblg/dict-twblg.json dicts/kisaragi/kisaragi_dict.json dicts/ministry-of-education/dict_idioms.json dicts/process-data.el
	cask eval "(load \"dicts/process-data\")"
	mkdir -p src/_data
	cp dicts/combined.json dicts/titles.json src/_data/

src/_data/kisaragi_dict.json: dicts/kisaragi/kisaragi_dict.json
	cp dicts/kisaragi/kisaragi_dict.json src/_data/

dicts/kisaragi/kisaragi_dict.json: dicts/kisaragi/kisaragi-dict.org dicts/kisaragi/generate.el
	cask eval "(load \"dicts/kisaragi/generate\")"

dicts/moedict-data-twblg/dict-twblg.json:
	git submodule update --init -- dicts/moedict-data-twblg

dicts/ministry-of-education/dict_idioms.json:
	git submodule update --init -- dicts/ministry-of-education

# * Development tasks
.PHONY: dev-11ty dev-tailwind dev dev-js kisaragi-dict-rebuild clear-dev-dicts

dev-11ty:
	npx "@11ty/eleventy" --input=./src --output=./_site --serve

dev-tailwind:
	npx tailwindcss --postcss -i css/src.css -o _site/b.css --watch

kisaragi-dict-rebuild: dicts/kisaragi/kisaragi_dict.json
clear-dev-dicts:
	rm dev-dict*.json

JS := _site/s.js _site/render-not-found.js

# This is for unconditionally updating the client side JS during
# development.
dev-js:
	make _site/s.js
	make _site/render-not-found.js

dev: $(JS)
	export DEV=true
	make src/_data
	npx concurrently "make dev-11ty" "make dev-tailwind"

# * Making the site itself
_site: src/*.njk src/_data _site/b.css $(JS) .eleventy.js
	npx --node-options='--max-old-space-size=7168' "@11ty/eleventy" --quiet

build: _site

public.zip: _site
	cd _site/ && 7z a ../public.zip .

_site/b.css: css/src.css
	npx tailwindcss --minify --postcss -i css/src.css -o _site/b.css

_site/%.js: client-side-js/%.ts .babelrc.json
	npx babel "$<" --out-file "$@"

