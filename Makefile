all: renumber next

renumber:
	./.scripts/$@.sh

next:
	./.scripts/$@.sh

.PHONY: all renumber next
