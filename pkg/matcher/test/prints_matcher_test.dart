// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.prints_matchers_test;

import 'dart:async';

import 'package:matcher/matcher.dart';
import 'package:unittest/unittest.dart';

import 'test_utils.dart';

void main() {
  initUtils();

  group('synchronous', () {
    test("passes with an expected print", () {
      shouldPass(() => print("Hello, world!"), prints("Hello, world!\n"));
    });

    test("combines multiple prints", () {
      shouldPass(() {
        print("Hello");
        print("World!");
      }, prints("Hello\nWorld!\n"));
    });

    test("works with a Matcher", () {
      shouldPass(() => print("Hello, world!"), prints(contains("Hello")));
    });

    test("describes a failure nicely", () {
      shouldFail(() => print("Hello, world!"), prints("Goodbye, world!\n"),
          "Expected: prints 'Goodbye, world!\\n' ''"
          "  Actual: <Closure: () => dynamic> "
          "   Which: printed 'Hello, world!\\n' ''"
          "   Which: is different. "
          "Expected: Goodbye, w ... "
          "  Actual: Hello, wor ... "
          "          ^ Differ at offset 0");
    });

    test("describes a failure with a non-descriptive Matcher nicely", () {
      shouldFail(() => print("Hello, world!"), prints(contains("Goodbye")),
          "Expected: prints contains 'Goodbye'"
          "  Actual: <Closure: () => dynamic> "
          "   Which: printed 'Hello, world!\\n' ''");
    });

    test("describes a failure with no text nicely", () {
      shouldFail(() {}, prints(contains("Goodbye")),
          "Expected: prints contains 'Goodbye'"
          "  Actual: <Closure: () => dynamic> "
          "   Which: printed nothing.");
    });
  });

  group('asynchronous', () {
    test("passes with an expected print", () {
      shouldPass(() => new Future(() => print("Hello, world!")),
          prints("Hello, world!\n"));
    });

    test("combines multiple prints", () {
      shouldPass(() => new Future(() {
        print("Hello");
        print("World!");
      }), prints("Hello\nWorld!\n"));
    });

    test("works with a Matcher", () {
      shouldPass(() => new Future(() => print("Hello, world!")),
          prints(contains("Hello")));
    });

    test("describes a failure nicely", () {
      shouldFail(() => new Future(() => print("Hello, world!")),
          prints("Goodbye, world!\n"),
          "Expected: 'Goodbye, world!\\n' ''"
          "  Actual: 'Hello, world!\\n' ''"
          "   Which: is different. "
          "Expected: Goodbye, w ... "
          "  Actual: Hello, wor ... "
          "          ^ Differ at offset 0",
          isAsync: true);
    });

    test("describes a failure with a non-descriptive Matcher nicely", () {
      shouldFail(() => new Future(() => print("Hello, world!")),
          prints(contains("Goodbye")),
          "Expected: contains 'Goodbye'"
          "  Actual: 'Hello, world!\\n' ''",
          isAsync: true);
    });

    test("describes a failure with no text nicely", () {
      shouldFail(() => new Future.value(), prints(contains("Goodbye")),
          "Expected: contains 'Goodbye'"
          "  Actual: ''",
          isAsync: true);
    });
  });
}
