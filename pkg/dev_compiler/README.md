dev_compiler
============

[![Build Status](https://travis-ci.org/dart-lang/dev_compiler.svg?branch=master)](https://travis-ci.org/dart-lang/dev_compiler)
[![Coverage Status](https://coveralls.io/repos/dart-lang/dev_compiler/badge.svg?branch=master)](https://coveralls.io/r/dart-lang/dev_compiler)

This is an **experimental** Dart->JavaScript compiler designed to create
idiomatic, readable JavaScript output. We're investigating this because
we want to enable easy debugging of Dart applications on all supported
browsers.

The initial target for this work is Chrome, which is why there's an ES6
backend. Longer term, we plan to investigate supporting all browsers that
Dart supports.
