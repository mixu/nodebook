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

.PHONY: build generate ebook book.mobi book.epub
