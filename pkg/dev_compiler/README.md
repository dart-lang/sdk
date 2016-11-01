dev_compiler
============

[![Build Status](https://travis-ci.org/dart-lang/sdk.svg?branch=master)](https://travis-ci.org/dart-lang/sdk)
[![Coverage Status](https://coveralls.io/repos/dart-lang/sdk/badge.svg?branch=master)](https://coveralls.io/r/dart-lang/sdk)

The Dart Dev Compiler (DDC) is an **experimental** development tool and transpiler.  It is at a very early stage today.  Its aims include the following:

- A static checker based on stricter-than-standard-Dart type rules.
- A modular Dart-to-ES6 transpiler for Dart programs that statically check.

DDC attempts to map to idiomatic EcmaScript 6 (ES6) as cleanly as possible.  To do this while cohering to Dart semantics, DDC relies heavily on static type information, static checking, and runtime assertions.

DDC is intended to support a very [large subset](https://github.com/dart-lang/sdk/blob/master/pkg/dev_compiler/STRONG_MODE.md) of Dart.  If a program does not statically check, DDC will not result in valid generated code.  Our goal is that a program execution (of a valid program) that runs without triggering runtime assertions should run the same on other Dart platforms under checked mode or production mode.

DDC does support untyped Dart code, but it will typically result in less readable and less efficient ES6 output.

DDC has the following project goals:

- Effective static checking and error detection.
- A debugging solution for all modern browsers.
- Readable output.
- Fast, modular compilation of Dart code.
- Easy use of generated code from JavaScript.

DDC is still in a very early stage as highlighted by our choice of ES6.  ES6 itself is in active development across all modern browsers, but at various stages of support:
[kangax.github.io/compat-table/es6](https://kangax.github.io/compat-table/es6/).

We are targeting the subset of ES6 supported in Chrome.

To try out DDC and/or give feedback, please read our [usage](https://github.com/dart-lang/sdk/blob/master/pkg/dev_compiler/USAGE.md) page.
