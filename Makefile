# Makefile for MathScript Compiler

# Compiler and flags
CC = gcc
# Added -Isrc to tell GCC where to find our .h files
CFLAGS = -g -Wall -Wno-unused-function -Isrc
LIBS = -lm

# Flex and Bison
FLEX = flex
BISON = bison

# Directories
SRC_DIR = src
OBJ_DIR = . # Keep objects in root for simplicity
EXAMPLES_DIR = examples
OUTPUT_DIR = output # NEW: Output directory

# Source files
C_SRCS = $(SRC_DIR)/ast.c $(SRC_DIR)/codegen.c $(SRC_DIR)/main.c $(SRC_DIR)/semantic.c
OBJS = $(C_SRCS:.c=.o)

# Generated files
GEN_SRCS = y.tab.c lex.yy.c
GEN_OBJS = y.tab.o lex.yy.o
GEN_HEADERS = y.tab.h

# Executable name
TARGET = mathsc

# --- Primary Targets ---

all: $(TARGET)

$(TARGET): $(OBJS) $(GEN_OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS) $(GEN_OBJS) $(LIBS)

# --- Compilation Rules ---

# Compile .c files from src/
$(SRC_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# Compile generated .c files
y.tab.o: y.tab.c
	$(CC) $(CFLAGS) -c y.tab.c -o y.tab.o

lex.yy.o: lex.yy.c
	$(CC) $(CFLAGS) -c lex.yy.c -o lex.yy.o

# --- Generation Rules ---

# Generate parser
y.tab.c y.tab.h: $(SRC_DIR)/mathscript.y
	$(BISON) -d -v -o y.tab.c $(SRC_DIR)/mathscript.y

# Generate lexer
lex.yy.c: $(SRC_DIR)/mathscript.l
	$(FLEX) -o lex.yy.c $(SRC_DIR)/mathscript.l

# --- Testing Target ---

# List of example files
EXAMPLES = $(wildcard $(EXAMPLES_DIR)/*.ms)

# This target depends on 'all' to ensure the compiler is built
test: all
	@echo "--- Running MathScript Compiler Tests ---"
	@mkdir -p $(OUTPUT_DIR) # NEW: Create output directory
	@for ex in $(EXAMPLES); do \
		echo "\n--- Testing $$ex ---"; \
		BASENAME=$$(basename $$ex .ms); \
		./$(TARGET) $$ex $(OUTPUT_DIR)/$${BASENAME}.py; \
		if [ $$? -eq 0 ]; then \
			python3 $(OUTPUT_DIR)/$${BASENAME}.py; \
		fi \
	done
	@echo "\n--- All tests complete ---"

# --- Cleanup ---

clean:
	rm -f $(TARGET)
	rm -f $(SRC_DIR)/*.o
	rm -f $(GEN_OBJS) $(GEN_SRCS) $(GEN_HEADERS)
	rm -rf $(OUTPUT_DIR) # NEW: Remove the entire output directory