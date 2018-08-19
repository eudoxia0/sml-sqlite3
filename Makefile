MLTON := mlton
MLTON_OPTS := -default-ann 'allowFFI true' -link-opt '-lsqlite3'
MLB_FILE := sml-sqlite3.mlb
SRC := src/*.sig src/*.sml $(MLB_FILE)

.PHONY: build

build: $(MLB_FILE) $(SRC)
	$(MLTON) $(MLTON_OPTS) $(MLB_FILE)
