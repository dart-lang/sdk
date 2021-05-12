// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Tests where late variable or field has a predictable value. An incorrect
// optimization might try to eliminate part of the check.

String lastTag = 'unset';

int zero(String tag) {
  lastTag = tag;
  return 0;
}

int one(String tag) {
  lastTag = tag;
  return 1;
}

int? returnNull(String tag) {
  lastTag = tag;
  return null;
}

class C1 {
  late int? i1 = zero('C1.i1');
  late int i2 = zero('C1.i2');
  late int? i3 = returnNull('C1.i3');
  late int i4 = one('C1.i4');
}

class C2 {
  late final int? i1 = zero('C2.i1');
  late final int i2 = zero('C2.i2');
  late final int? i3 = returnNull('C2.i3');
  late int i4 = one('C2.i4');
}

void test1() {
  for (int i = 0; i < 10; i++) {
    final c = C1();
    lastTag = '';
    Expect.equals(0, c.i1);
    Expect.equals('C1.i1', lastTag);
    Expect.equals(0, c.i2);
    Expect.equals('C1.i2', lastTag);
    Expect.equals(null, c.i3);
    Expect.equals('C1.i3', lastTag);

    Expect.equals(0, c.i1);
    Expect.equals('C1.i3', lastTag);
    Expect.equals(0, c.i2);
    Expect.equals('C1.i3', lastTag);
    Expect.equals(null, c.i3);
    Expect.equals('C1.i3', lastTag);

    Expect.equals(1, c.i4);
    Expect.equals('C1.i4', lastTag);
  }
}

void test2() {
  final c = C2();
  lastTag = '';
  Expect.equals(0, c.i1);
  Expect.equals('C2.i1', lastTag);
  Expect.equals(0, c.i2);
  Expect.equals('C2.i2', lastTag);
  Expect.equals(null, c.i3);
  Expect.equals('C2.i3', lastTag);

  Expect.equals(0, c.i1);
  Expect.equals('C2.i3', lastTag);
  Expect.equals(0, c.i2);
  Expect.equals('C2.i3', lastTag);
  Expect.equals(null, c.i3);
  Expect.equals('C2.i3', lastTag);

  Expect.equals(1, c.i4);
  Expect.equals('C2.i4', lastTag);
}

main() {
  test1();
  test2();
}
