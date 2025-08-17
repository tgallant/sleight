# sleight

Sleight is a toy scheme implementation written in lua.

## Standard Library

- [X] assert
- [X] test!
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
- [X] add more builtins
  - [X] cons
  - [X] car
  - [X] cdr
  - [X] support booleans
  - [X] support null
  - [X] support cons pair
  - [X] update parse + eval to use cons paris
  - [X] null?/symbol?/number?/string?/pair?/list?
  - [X] pretty print for scheme values
- [ ] builtin testing
  - [X] test! function that runs all fns named "test-"
  - [ ] make sure tests always run in the same order
- [X] support comments
- [ ] add support for macros
  - [X] add support for quote
  - [ ] add support for quasiquote
  - [ ] implement macro primitives
  - [ ] handle macros in evaluator
- [X] support define function syntax
- [ ] start building standard lib
  - [ ] create scm/lib.scm
  - [ ] load lib.scm into environment before eval
- [ ] better error handling
- [ ] repl history
- [ ] support geiser repl in emacs
- [ ] compile to lua bytecode (?)
