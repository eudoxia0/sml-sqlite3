MLTON := mlton
MLTON_OPTS := -link-opt '-lsqlite3'
MLB_FILE := sml-sqlite3.mlb
SRC := src/*.sig src/*.sml $(MLB_FILE)

TEST_MLB_FILE := sml-sqlite3-test.mlb
TEST_SRC := $(SRC) $(MLB_FILE)
TEST_BIN := sml-sqlite3-test

.PHONY: build test

build: $(MLB_FILE) $(SRC)
	$(MLTON) $(MLTON_OPTS) $(MLB_FILE)

test: $(TEST_MLB_FILE) $(MLB_FILE) $(SRC)
	$(MLTON) $(MLTON_OPTS) $(TEST_MLB_FILE)
	./$(TEST_BIN)

clean:
	rm sml-sqlite3
	rm $(TEST_BIN)
	rm testdb
