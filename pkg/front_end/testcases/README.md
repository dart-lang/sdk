<!--
  -- Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
  -- for details. All rights reserved. Use of this source code is governed by a
  -- BSD-style license that can be found in the LICENSE file.
  -->
# Overview

The testcases in this directory and its subdirectory are all compiled in various different configurations designed to test various aspects of Fasta (or more generally, package:front_end).

The configurations are described below.

The source of truth for these configurations is the file [pkg/front_end/testing.json](../testing.json).

## ast_builder

* Status file: [ast_builder.status](ast_builder.status)
* Standalone test: [pkg/front_end/test/fasta/ast_builder_test.dart](../test/fasta/ast_builder_test.dart)
* Expectation prefix: N/A
* How to update expectations: N/A

This configuration doesn't have expectations as it doesn't produce Kernel AST nodes.


## Dart 1.0 Compilation

* Status file: [compile.status](compile.status)
* Standalone test: [pkg/front_end/test/fasta/compile_test.dart](../test/fasta/compile_test.dart)
* Expectation prefix: `.direct.expect`
* How to update expectations:

```
./pkg/front_end/tool/fasta testing -DupdateExpectations=true compile/test1 compile/test2 ...
```


## Dart 1.0 Outlines

* Status file: [outline.status](outline.status)
* Standalone test: [pkg/front_end/test/fasta/outline_test.dart](../test/fasta/outline_test.dart)
* Expectation prefix: `.outline.expect`
* How to update expectations:

```
./pkg/front_end/tool/fasta testing -DupdateExpectations=true outline/test1 outline/test2 ...
```

## Tree Shaking

* Status file: [shaker.status](shaker.status)
* Standalone test: [pkg/front_end/test/fasta/shaker_test.dart](../test/fasta/shaker_test.dart)
* Expectation prefix: `.shaker.expect`
* How to update expectations:

```
./pkg/front_end/tool/fasta testing -DupdateExpectations=true shaker/test1 shaker/test2 ...
```

## Dart 2.0 (strong mode)

* Status file: [strong.status](strong.status)
* Standalone test: [pkg/front_end/test/fasta/strong_test.dart](../test/fasta/strong_test.dart)
* Expectation prefix: `.strong.expect`
* How to update expectations:

```
./pkg/front_end/tool/fasta testing -DupdateExpectations=true -DupdateComments=true strong/test1 strong/test2 ...
```

Note: strong mode configuration additionally parses comments in the test file and can precisely match internal details of the compiler such as the inferred type of an expression or if a warning was emitted at a given location.
