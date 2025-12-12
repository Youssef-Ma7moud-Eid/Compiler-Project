# Dart Compiler Project

This repository contains a complete compiler project built using **Flex** for lexical analysis and **Bison** for parsing. The compiler processes a Dart-like programming language, handling variable declarations, assignments, arithmetic/logical operations, control flow structures, and error reporting.


##  🚀 Quick Start

### Prerequisites
- **Flex** (Fast Lexical Analyzer)
- **Bison** (GNU Parser Generator)
- **GCC** (GNU Compiler Collection)

### Compilation Steps
1. **Generate the parser:**
    ```bash
    bison -d parser.y
    Output: parser.tab.c and parser.tab.h
    
2. **Generate the lexical analyzer:**
   ```bash
   flex flex.l
   Output: lex.yy.c

3.   **Compile the compiler:**
     ```bash
     gcc -o compiler.exe parser.tab.c lex.yy.c -lm
      Output: compiler.exe

4. **Running the Compiler**
    ```bash
    ./compiler.exe
    
 ##  📂 Project Structure
  ```css
├── compiler.exe # Compiled executable
├── error.txt # Error output file
├── flex.l # Flex lexical analyzer rules
├── in.txt # Input Dart code to compile
├── lex.yy.c # Generated scanner C code
├── out.txt # Compilation output
├── parser.tab.c # Generated parser C code
├── parser.tab.h # Generated parser header
└── parser.y # Bison parser grammar


