// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js produces the expected static type warnings for proxy
// language tests. This ensures that the analyzer and dart2js agrees on these
// tests.

import 'warnings_checker.dart';

/// Map from test files to a map of their expected status. If the status map is
/// `null` no warnings must be missing or unexpected, otherwise the status map
/// can contain a list of line numbers for keys 'missing' and 'unexpected' for
/// the warnings of each category.
const Map<String, dynamic> TESTS = const {
  'language/null_is_bottom_type_test.dart': null,
};

void main(List<String> args) {
  checkWarnings(TESTS, args);
}
