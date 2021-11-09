// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

class BadToString {
  @override
  String toString() => null;
}

void test(expected, object) {
  var message = '';
  if (expected == null) {
    Expect.throws(() => '$object',
        (error) => '$error'.contains("toString method returned 'null'"));
  } else {
    Expect.equals(expected, '$object');
  }
}

void main() {
  test("123", 123);
  test("null", null);
  test(null, BadToString());
  test(null, [BadToString()]);
  test(null, {BadToString()});
}
