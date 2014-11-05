// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js produces the expected static type warnings and
// compile-time errors for these tests.

import 'frontend_checker.dart';

const List<String> TESTS = const <String>[
  'compiler/dart2js/async_await_syntax.dart',
];

void main(List<String> arguments) {
  check(TESTS, arguments: arguments, options: ['--enable-async']);
}
