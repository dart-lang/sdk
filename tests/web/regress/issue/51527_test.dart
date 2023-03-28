// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/51527

import 'package:expect/expect.dart';

void noop() {}
dynamic makeNull() => null;

String test(String? o) {
  switch (o) {
    case null:
      return 'NULL';
    case 'one':
      return '1';
    default:
      return o;
  }
}

void main() {
  final String? s1 = 'one';
  final String? s2 = 'two';
  final String? s3 = Function.apply(makeNull, []);
  final String? s4 = Function.apply(noop, []);

  Expect.equals('1', test(s1));
  Expect.equals('two', test(s2));
  Expect.equals('NULL', test(s3));
  Expect.equals('NULL', test(s4));
}
