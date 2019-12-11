// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for the "is" type test operator.

import "package:expect/expect.dart";

check(args) {
  var list = args[0];
  var string = args[1];
  var nullObject = args[2];

  Expect.isTrue(list is Object);
  Expect.isTrue(list is List);
  Expect.isTrue(list is Iterable);
  Expect.isFalse(list is Comparable);
  Expect.isFalse(list is Pattern);
  Expect.isFalse(list is String);

  Expect.isFalse(list is! List);
  Expect.isFalse(list is! Iterable);
  Expect.isTrue(list is! Comparable);
  Expect.isTrue(list is! Pattern);
  Expect.isTrue(list is! String);

  Expect.isTrue(string is Object);
  Expect.isFalse(string is List);
  Expect.isFalse(string is Iterable);
  Expect.isTrue(string is Comparable);
  Expect.isTrue(string is Pattern);
  Expect.isTrue(string is String);

  Expect.isTrue(string is! List);
  Expect.isTrue(string is! Iterable);
  Expect.isFalse(string is! Comparable);
  Expect.isFalse(string is! Pattern);
  Expect.isFalse(string is! String);

  Expect.isTrue(nullObject is Object);
  Expect.isFalse(nullObject is List);
  Expect.isFalse(nullObject is Iterable);
  Expect.isFalse(nullObject is Comparable);
  Expect.isFalse(nullObject is Pattern);
  Expect.isFalse(nullObject is String);

  Expect.isTrue(nullObject is! List);
  Expect.isTrue(nullObject is! Iterable);
  Expect.isTrue(nullObject is! Comparable);
  Expect.isTrue(nullObject is! Pattern);
  Expect.isTrue(nullObject is! String);
}

main() {
  // Try to make it hard for an optimizing compiler to inline the
  // tests.
  check([[], 'string', null]);

  // Try to make it even harder.
  var string = new String.fromCharCodes([new DateTime.now().year % 100 + 1]);
  check([string.codeUnits, string, null]);
}
