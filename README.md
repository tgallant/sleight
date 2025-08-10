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
  - [X] support booleans
  - [X] support null
  - [X] support cons pair
  - [X] update parse + eval to use cons paris
  - [X] null?/symbol?/number?/string?/pair?/list?
  - [X] pretty print for scheme values
- [ ] add support for macros
  - [X] add support for quote
  - [ ] add support for quasiquote
  - [ ] implement macro primitives
  - [ ] handle macros in evaluator
- [ ] start building standard lib
- [ ] better error handling
- [ ] repl history
- [ ] compile to lua bytecode (?)
