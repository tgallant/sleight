# sleight

Sleight is a toy scheme implementation written in lua.

## Standard Library

- [X] assert
- [ ] test
- [ ] test-run
- [ ] basic macros
- [ ] define macro
- [ ] arrow macros

## Defining Macros

- `define-macro` - unhygenic

## Changelog

- [X] add support for strings
- [X] add print function
- [X] evaluate from file
- [X] move tests to separate file
- [ ] add more builtins
  - [X] cons
  - [X] car
  - [X] cdr
  - [ ] null?/symbol?/number?/pair?
  - [ ] pretty print for lists/pairs
- [ ] add support for macros
  - [X] add support for quote
  - [ ] add support for quasiquote
  - [ ] implement macro primitives
  - [ ] handle macros in evaluator
- [ ] start building standard lib
- [ ] compile to lua bytecode (?)
