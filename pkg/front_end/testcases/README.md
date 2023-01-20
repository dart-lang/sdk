<!--
  -- Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
  -- for details. All rights reserved. Use of this source code is governed by a
  -- BSD-style license that can be found in the LICENSE file.
  -->
# Overview

The testcases in this directory and its subdirectory are all compiled in various different configurations designed to test various aspects of Fasta (or more generally, package:front_end).

The configurations are described below.

The source of truth for these configurations is the file [pkg/front_end/testing.json](../testing.json).

## Updating all expectations
To update test expectations for all tests at once, run:
```bash
dart pkg/front_end/tool/update_expectations.dart
```
Note that this takes a long time and should only be used when many tests need updating.

## Updating expectations for a single test
To update the expectations for a specific test, provide the folder and test name as an argument.

For example, if you want to update the test expectations for a test, such as `pkg/front_end/testcases/general/abstract_instantiation.dart`, then run:
```bash
dart pkg/front_end/tool/update_expectations.dart general/abstract_instantiation
```

## Updating expectations for all tests in a folder
If you want to update the test expectations for a specific folder of tests such as the `pkg/front_end/testcases/general/` folder, then run:
```bash
dart pkg/front_end/tool/update_expectations.dart general/...
```

## Dart 1.0 Outlines

* Status file: [outline.status](outline.status)
* Standalone test: [pkg/front_end/test/fasta/outline_test.dart](../test/fasta/outline_test.dart)
* Expectation prefix: `.outline.expect`
* How to update expectations:

```
./pkg/front_end/tool/fasta testing -DupdateExpectations=true outline/test1 outline/test2 ...
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
