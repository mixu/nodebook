build: generate ebook

generate:
	node generate.js

ebook: book.mobi book.epub

book.mobi:
	@echo "\n... generating $@"
	ebook-convert output/single.html output/mixu-node-book.mobi \
		--title "Mixu's Node book" \
		--authors "Mikito Takada" \
		--language en \
		--output-profile kindle || true

book.epub:
	@echo "\n... generating $@"
	ebook-convert output/single.html output/mixu-node-book.epub \
		--title "Mixu's Node book" \
		--no-default-epub-cover \
		--authors "Mikito Takada" \
		--language en || true

upload:
	aws s3 sync ./output/ s3://book.mixu.net/node/ \
	--region us-west-1 \
	--delete \
	--exclude "node_modules/*" \
	--exclude ".git" \
	--exclude ".DS_Store"

.PHONY: upload

.PHONY: build generate ebook book.mobi book.epub
