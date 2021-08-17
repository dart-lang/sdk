// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for corner cases of 'a.runtimeType == b.runtimeType' pattern
// which is recognized and optimized in AOT mode.

// @dart = 2.9

import "package:expect/expect.dart";

@pragma('vm:never-inline')
Object getType(Object obj) => obj.runtimeType;

@pragma('vm:never-inline')
void test(bool expected, Object a, Object b) {
  bool result1 = getType(a) == getType(b);
  bool result2 = a.runtimeType == b.runtimeType;
  Expect.equals(expected, result1);
  Expect.equals(expected, result2);
}

typedef Func = void Function();

void main() {
  test(true, 0x7fffffffffffffff, int.parse('42'));
  test(true, 'hi', String.fromCharCode(1114111));
  test(false, 'hi', 1);
  test(true, List, Func);
  test(true, <int>[1], const <int>[2]);
  test(true, const <String>[], List<String>.filled(1, ''));
  test(true, <String>[]..add('hi'), List<String>.filled(2, ''));
  test(false, <int>[], <String>[]);
}
