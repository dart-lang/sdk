// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

import "package:expect/expect.dart";

/// Expects that [expected] appears as a substring in [actual].
expectStringContains(String expected, String actual) {
  Expect.isTrue(actual.contains(expected),
      'Failure: "$expected" should appear in: "$actual".');
}
