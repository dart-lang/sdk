// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=wildcard-variables

// ignore: invalid_language_version_override
// @dart = 3.7

import 'dart:developer';
// Tests wildcard import prefixes.
// ignore: unused_import, library_prefixes, no_leading_underscores_for_library_prefixes
import 'dart:io' as _;

import 'common/test_helper.dart';

void test() {
  // We define an anonymous function instead of a named one because wildcard
  // parameters can be optimized out of named functions by the compiler, so
  // defining a named function would prevent this test from exercising the
  // wildcard filtering logic in the VM Service's [Frame] building code.
  // ignore: prefer_function_declarations_over_variables
  final foo = <_>(i, _, _) {
    final int _ = 42;
    debugger();
  };

  foo<String>(0, 1, 2);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: test);
}
