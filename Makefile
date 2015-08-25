all:


.PHONY: test
test:
	@shellcheck ./bbuild
	@./test_bbuild
