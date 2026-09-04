.PHONY: build test release quality

build:
	swift build

test:
	swift test

release:
	swift build -c release

quality:
	bash Scripts/check-quality.sh
