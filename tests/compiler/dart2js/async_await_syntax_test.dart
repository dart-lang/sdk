// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js produces the expected static type warnings and
// compile-time errors for these tests.

import 'frontend_checker.dart';

/// Map of test files to run together with their associated whitelist.
///
/// For instance
///     'language/async_await_syntax_test.dart': const ['a03b', 'a04b']
/// includes the multitest in 'language/async_await_syntax_test.dart' but
/// expects the subtests 'a03b' and 'a04c' to fail.
const Map<String, List<String>> TESTS = const <String, List<String>>{
  'language_2/async_await_syntax_test.dart': const [
    'a10a',
    'b10a',
    'c10a',
    'd08b',
    'd10a',
  ],
};

void main(List<String> arguments) {
  check(TESTS, arguments: arguments, options: []);
}
