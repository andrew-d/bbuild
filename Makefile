all:

.PHONY: lint
lint:
	@shellcheck --shell=bash ./bbuild || true

.PHONY: test
test:
	@./test_bbuild
