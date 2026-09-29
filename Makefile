all: renumber next

renumber:
	./.scripts/$@.sh

new:
	./.scripts/$@.sh

.PHONY: all renumber new
