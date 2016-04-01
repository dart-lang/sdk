# dev_compiler changelog

## 0.1.24
- workaround breaking change on requestAnimationFrame

## 0.1.23
- updates for the latest analyzer
- removal of deprecated functionality (server mode) in prep for refactoring

## 0.1.22
- fixes to support the latest analyzer
- improvements in compile speed
- bug fixes on function / closure handling

## 0.1.21
- bug fix for dart:js constructor invocation

## 0.1.20
- support new StackTrace.current method

## 0.1.19
- support for dom libraries (dart:html, etc)

## 0.1.18
- dart:typed_data support
- preliminary TS / Closure output support
- various runtime typing fixes

## 0.1.17
- preliminary node module support
- support for compiling / serving multiple html files

## 0.1.16
- rolled analyzer to 0.27.2-alpha.1
- fixes for static fields

## 0.1.15
- codegen fixes for dart:convert (json decode) and dart:math (max, min)

## 0.1.14
- updates to unpin analyzer and move forward to ^0.27.1+2

## 0.1.13
- various fixes in js codegen
- pinned to analyzer 0.26.2+1 to avoid breaking upstream changes

## 0.1.12
- fixes for babel
- fixes toward new js interop

## 0.1.11
- moved js runtime files to lib/runtime/dart (`dart_runtime.js` -> `dart/_runtime.js`)
- bug fix to source maps
- initial support for f-bound quantification patterns

## 0.1.10
- added an `--html-report` option to create a file summarizing compilation
  issues
- added a `-f` alias to the `--force-compile` command line option
- removed many info level messages that were informational to the DDC team

## 0.1.9

## 0.1.8
- added a `--version` command-line option
- added a new entry-point - `dev_compiler` - that aliases to `dartdevc`
