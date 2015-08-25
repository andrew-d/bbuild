all:


.PHONY: test
test:
	@shellcheck ./bbuild
	@./bbuild_test
