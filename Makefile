book: concat
	generate-md \
	--layout ./layout \
	--input ./content \
	--output ./output

.PHONY: book

concat:
	rm -rf ./tmp || true
	mkdir ./tmp
	cat content/index.md > ./tmp/single.md
	cat content/ch1.md | bin/remove-meta.js >> ./tmp/single.md
	cat content/ch2.md | bin/remove-meta.js>> ./tmp/single.md
	cat content/ch3.md | bin/remove-meta.js >> ./tmp/single.md
	cat content/ch4.md | bin/remove-meta.js >> ./tmp/single.md
	cat content/ch5.md | bin/remove-meta.js >> ./tmp/single.md
	cat content/ch6.md | bin/remove-meta.js >> ./tmp/single.md
	cat content/ch7.md | bin/remove-meta.js >> ./tmp/single.md
	cat content/ch8.md | bin/remove-meta.js >> ./tmp/single.md
	cat content/ch9.md | bin/remove-meta.js >> ./tmp/single.md
	cat content/ch10.md | bin/remove-meta.js >> ./tmp/single.md
	cat content/ch11.md | bin/remove-meta.js >> ./tmp/single.md
	cat content/ch13.md | bin/remove-meta.js >> ./tmp/single.md
	generate-md \
	--input ./tmp/single.md \
	--layout ./layout \
	--output ./output
	cp ./output/single.html ./output/single-page.html

.PHONY: concat

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
